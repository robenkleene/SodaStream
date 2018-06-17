//
//  SDATaskRunnerTests.swift
//  Web Console
//
//  Created by Roben Kleene on 11/28/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

@testable import SodaStream
import XCTest

extension SDATaskRunnerTests: SDATaskRunnerDelegate {
    func task(_: Process, didFailToRunCommandPath _: String, error: Error) {
        XCTAssertNotNil(error)
        XCTAssert((error as NSError).code == RunCommandPathErrorCode.unexecutable.rawValue)
        if let didFailToRunCommandPathExpectation = didFailToRunCommandPathExpectation {
            didFailToRunCommandPathExpectation.fulfill()
        }
    }
}

class SDATaskRunnerTests: XCTestCase {
    var didFailToRunCommandPathExpectation: XCTestExpectation?

    func testInvalidCommandPath() {
        let expection = expectation(description: "Run task")
        didFailToRunCommandPathExpectation = expectation(description: "Did fail to run command path")

        SDATaskRunner.runTask(withCommandPath: "invalid path", withArguments: nil, inDirectoryPath: nil, delegate: self) { (success) -> Void in
            XCTAssertFalse(success)
            expection.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
