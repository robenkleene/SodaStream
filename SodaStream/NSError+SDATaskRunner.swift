//
//  NSError+SDATaskRunner.swift
//  Web Console
//
//  Created by Roben Kleene on 12/19/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

enum RunCommandPathErrorCode: Int {
    case unknown = 100, unexecutable, exception
}

// MARK: SDATaskRunner

// `public` and `@objc` to be called from Objective-C
@objc public extension NSError {
    class func commandPathUnkownError(launchPath: String) -> NSError {
        return makeError(description: "An unkown error occurred running command path: \(launchPath)",
                         code: RunCommandPathErrorCode.unknown.rawValue)
    }

    class func commandPathUnexecutableError(launchPath: String) -> NSError {
        return makeError(description: "Command path is not executable: \(launchPath)",
                         code: RunCommandPathErrorCode.unexecutable.rawValue)
    }

    class func commandPathExceptionError(launchPath: String) -> NSError {
        return makeError(description: "An exception was thrown running command path: \(launchPath)",
                         code: RunCommandPathErrorCode.exception.rawValue)
    }
}
