//
//  NSError+TaskResult.swift
//  Web Console
//
//  Created by Roben Kleene on 1/6/16.
//  Copyright © 2016 Roben Kleene. All rights reserved.
//

import Foundation

extension NSError {
    
    enum TaskTerminatedUserInfoKey: NSString {
        case exitStatus = "ExitStatus"
    }
    
    enum TaskTerminatedErrorCode: Int {
        case uncaughtSignal = 100, nonzeroExitStatus
    }
    
    class func makeTaskTerminatedUncaughtSignalError(launchPath: String?,
        arguments: [String]?,
        directoryPath: String?,
        standardError: String?) -> NSError
    {
        var description = "An uncaught signal error occurred"
        if let launchPath = launchPath {
            description += " running launch path: \(launchPath)"
        }
        
        if let arguments = arguments {
            description += ", with arguments: \(arguments)"
        }
        
        if let directoryPath = directoryPath {
            description += ", in directory path: \(directoryPath)"
        }
        
        if let standardError = standardError {
            description += ", standardError: \(standardError)"
        }
        
        return makeError(description: description, code: TaskTerminatedErrorCode.uncaughtSignal.rawValue)
    }
    
    class func makeTaskTerminatedNonzeroExitCodeError(launchPath: String?,
        exitCode: Int32,
        arguments: [String]?,
        directoryPath: String?,
        standardError: String?) -> NSError
    {
        var description = "Terminated with a nonzero exit status \(exitCode)"
        if let launchPath = launchPath {
            description += " running launch path: \(launchPath)"
        }
        
        if let arguments = arguments {
            description += ", with arguments: \(arguments)"
        }
        
        if let directoryPath = directoryPath {
            description += ", in directory path: \(directoryPath)"
        }
        
        if let standardError = standardError {
            description += ", standardError: \(standardError)"
        }
        
        let userInfo: [AnyHashable: Any] = [NSLocalizedDescriptionKey: description,
            TaskTerminatedUserInfoKey.exitStatus.rawValue: NSNumber(value: exitCode as Int32)]
        
        return makeError(userInfo: userInfo, code: TaskTerminatedErrorCode.nonzeroExitStatus.rawValue)
    }
    
    
}
