//
//  SDATastRunner+TaskResult.swift
//  Web Console
//
//  Created by Roben Kleene on 12/20/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

extension TaskResultsCollector: SDATaskRunnerDelegate {
    func taskDidFinishStandardOutputAndStandardError(_ task: Process) {
        assert(!task.isRunning)
        let error = makeError(for: task)
        completionHandler(standardOutput, standardError, error)
    }

    func taskDidFinish(_ task: Process) {
        assert(!task.isRunning)
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

private class TaskResultsCollector: NSObject {
    var standardOutput: String?
    var standardError: String?
    var error: NSError?

    let completionHandler: SDATaskRunner.TaskResult
    init(completionHandler: @escaping SDATaskRunner.TaskResult) {
        self.completionHandler = completionHandler
    }

    func appendToStandardOutput(_ text: String) {
        if standardOutput == nil {
            standardOutput = String()
        }

        standardOutput? += text
    }

    func appendToStandardError(_ text: String) {
        if standardError == nil {
            standardError = String()
        }

        standardError? += text
    }

    func makeError(for task: Process) -> NSError? {
        assert(!task.isRunning)
        if task.terminationStatus == 0, task.terminationReason == .exit {
            return nil
        }

        if task.terminationReason == .uncaughtSignal {
            return NSError.makeTaskTerminatedUncaughtSignalError(launchPath: task.launchPath,
                                                                 arguments: task.arguments,
                                                                 directoryPath: task.currentDirectoryPath,
                                                                 standardError: standardError)
        }

        return NSError.makeTaskTerminatedNonzeroExitCodeError(launchPath: task.launchPath,
                                                              exitCode: task.terminationStatus,
                                                              arguments: task.arguments,
                                                              directoryPath: task.currentDirectoryPath,
                                                              standardError: standardError)
    }
}

extension SDATaskRunner {
    public typealias TaskResult = (_ standardOutput: String?, _ standardError: String?, _ error: NSError?) -> Void

    public class func runTaskUntilFinished(withCommandPath commandPath: String,
                                           withArguments arguments: [String]?,
                                           inDirectoryPath directoryPath: String?,
                                           withEnvironment environment: [String: String]?,
                                           completionHandler: @escaping SDATaskRunner.TaskResult) -> Process {
        let timeout = 20.0
        return runTaskUntilFinished(withCommandPath: commandPath,
                                    withArguments: arguments,
                                    inDirectoryPath: directoryPath,
                                    withEnvironment: environment,
                                    timeout: timeout,
                                    completionHandler: completionHandler)
    }

    public class func runTaskUntilFinished(withCommandPath commandPath: String,
                                           withArguments arguments: [String]?,
                                           inDirectoryPath directoryPath: String?,
                                           withEnvironment environment: [String: String]?,
                                           timeout: TimeInterval,
                                           completionHandler: @escaping SDATaskRunner.TaskResult) -> Process {
        var optionalTaskResultsCollector: TaskResultsCollector?
        let taskResultsCollector = TaskResultsCollector { standardOutput, standardError, error in
            // Hold a strong reference to the `taskResultsCollector` until this block has run.
            let _ = optionalTaskResultsCollector
            optionalTaskResultsCollector = nil
            completionHandler(standardOutput, standardError, error)
        }
        optionalTaskResultsCollector = taskResultsCollector

        return runTaskWithCommandPath(commandPath,
                                      withArguments: arguments,
                                      inDirectoryPath: directoryPath,
                                      withEnvironment: environment,
                                      timeout: timeout,
                                      delegate: taskResultsCollector,
                                      completionHandler: nil)
    }

    class func runTaskWithCommandPath(_ commandPath: String,
                                      withArguments arguments: [String]?,
                                      inDirectoryPath directoryPath: String?,
                                      withEnvironment environment: [String: String]?,
                                      timeout: TimeInterval,
                                      delegate: SDATaskRunnerDelegate?,
                                      completionHandler: ((Bool, Process) -> Void)?) -> Process {
        let task = runTask(withCommandPath: commandPath,
                           withArguments: arguments,
                           inDirectoryPath: directoryPath,
                           withEnvironment: environment,
                           delegate: delegate,
                           completionHandler: completionHandler)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if task.isRunning {
                task.wcl_interrupt(completionHandler: { (success) -> Void in
                    if !success {
                        // If the interrupt fails, try a terminate as a
                        // last resort.
                        task.wcl_terminate(completionHandler: { (success) -> Void in
                            assert(success)
                        })
                    }
                })
            }
        }

        return task
    }
}
