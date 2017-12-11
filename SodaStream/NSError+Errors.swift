//
//  NSError+Errors.swift
//  Web Console
//
//  Created by Roben Kleene on 11/28/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

import Foundation

let errorDomain = Bundle(for: SDATaskRunner.self).bundleIdentifier!
let errorCode = 100

// MARK: Generic

extension NSError {

    class func makeError(description: String) -> NSError {
        return makeError(description: description, code: errorCode)
    }
    
    class func makeError(description: String, code: Int) -> NSError
    {
        return makeError(userInfo: [NSLocalizedDescriptionKey: description],
                         code: code)
    }

    class func makeError(userInfo: [String: Any],
                         code: Int) -> NSError
    {
        return NSError(domain: errorDomain,
                       code: code,
                       userInfo: userInfo)
    }

}
