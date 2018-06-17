//
//  SDATastRunner+TaskResult.swift
//  Web Console
//
//  Created by Roben Kleene on 12/20/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

extension TaskResultsCollector: SDATaskRunnerDelegate {
    func taskDidFinish(_ task: Process) {
        assert(!task.isRunning)
        let error = makeError(for: task)
        completionHandler(standardOutput, standardError, error)
    }

    func task(_ task: Process,
              didFailToRunCommandPath _: String,
              error: Error) {
        assert(!task.isRunning)
        completionHandler(standardOutput, standardError, error as NSError?)
    }

    func task(_: Process, didReadFromStandardError text: String) {
        appendToStandardError(text)
    }

    func task(_: Process, didReadFromStandardOutput text: String) {
        appendToStandardOutput(text)
    }
}

class TaskResultsCollector: NSObject {
    var standardOutput: String?
    var standardError: String?
    var error: NSError?

    let completionHandler: SDATaskRunner.TaskResult
    init(completionHandler: @escaping SDATaskRunner.TaskResult) {
        self.completionHandler = completionHandler
    }

    fileprivate func appendToStandardOutput(_ text: String) {
        if standardOutput == nil {
            standardOutput = String()
        }

        standardOutput? += text
    }

    fileprivate func appendToStandardError(_ text: String) {
        if standardError == nil {
            standardError = String()
        }

        standardError? += text
    }

    fileprivate func makeError(for task: Process) -> NSError? {
        assert(!task.isRunning)
        if task.terminationStatus == 0 && task.terminationReason == .exit {
            return nil
        }

        if task.terminationReason == .uncaughtSignal {
            return NSError.makeTaskTerminatedUncaughtSignalError(launchPath: task.launchPath,
                                                                 arguments: task.arguments,
                                                                 directoryPath: task.currentDirectoryPath,
                                                                 standardError: standardError)
        }

        return NSError.makeTaskTerminatedNonzeroExitCodeError(launchPath: task.launchPath, exitCode:
            task.terminationStatus,
            arguments: task.arguments,
            directoryPath: task.currentDirectoryPath,
            standardError: standardError)
    }
}

extension SDATaskRunner {
    public typealias TaskResult = (_ standardOutput: String?, _ standardError: String?, _ error: NSError?) -> Void

    public class func runTaskUntilFinished(withCommandPath commandPath: String,
                                           withArguments arguments: [AnyObject]?,
                                           inDirectoryPath directoryPath: String?,
                                           completionHandler: @escaping SDATaskRunner.TaskResult) -> Process {
        let timeout = 20.0
        return runTaskUntilFinished(withCommandPath: commandPath,
                                    withArguments: arguments,
                                    inDirectoryPath: directoryPath,
                                    timeout: timeout,
                                    completionHandler: completionHandler)
    }

    public class func runTaskUntilFinished(withCommandPath commandPath: String,
                                           withArguments arguments: [AnyObject]?,
                                           inDirectoryPath directoryPath: String?,
                                           timeout: TimeInterval,
                                           completionHandler: @escaping SDATaskRunner.TaskResult) -> Process {
        let taskResultsCollector = TaskResultsCollector { standardOutput, standardError, error in
            completionHandler(standardOutput, standardError, error)
        }

        return runTaskWithCommandPath(commandPath,
                                      withArguments: arguments,
                                      inDirectoryPath: directoryPath,
                                      timeout: timeout,
                                      delegate: taskResultsCollector,
                                      completionHandler: nil)
    }

    class func runTaskWithCommandPath(_ commandPath: String,
                                      withArguments arguments: [AnyObject]?,
                                      inDirectoryPath directoryPath: String?,
                                      timeout _: TimeInterval,
                                      delegate: SDATaskRunnerDelegate?,
                                      completionHandler: ((Bool) -> Void)?) -> Process {
        let task = runTask(withCommandPath: commandPath,
                           withArguments: arguments,
                           inDirectoryPath: directoryPath,
                           delegate: delegate,
                           completionHandler: completionHandler)

        let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if task.isRunning {
                task.wcl_interrupt(completionHandler: { (success) -> Void in
                    assert(success)
                })
            }
        }

        return task
    }
}
