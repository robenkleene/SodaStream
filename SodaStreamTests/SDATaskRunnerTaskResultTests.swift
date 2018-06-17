//
//  SDATaskRunnerTaskResultTests.swift
//  Web Console
//
//  Created by Roben Kleene on 12/20/15.
//  Copyright © 2015 Roben Kleene. All rights reserved.
//

@testable import SodaStream
import XCTest

class SDATaskRunnerTaskResultTests: XCTestCase {
    func testInterruptTask() {
        let commandPath = path(forResource: testDataShellScriptCatName,
                               ofType: testDataShellScriptExtension,
                               inDirectory: testDataSubdirectory)!

        let expectation = self.expectation(description: "Task finished")

        _ = SDATaskRunner.runTaskUntilFinished(withCommandPath: commandPath,
                                               withArguments: nil,
                                               inDirectoryPath: nil,
                                               timeout: 0.0) { (_, _, error) -> Void in
            XCTAssertNotNil(error)
            guard let error = error else {
                XCTAssertTrue(false)
                return
            }

            guard let description = error.userInfo[NSLocalizedDescriptionKey] as NSString else {
                XCTFail()
                return
            }
            XCTAssertTrue(description.hasPrefix("An uncaught signal error occurred"))

            expectation.fulfill()
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testStandardOutput() {
        let commandPath = path(forResource: testDataHelloWorld,
                               ofType: testDataRubyFileExtension,
                               inDirectory: testDataSubdirectory)!

        let expectation = self.expectation(description: "Task finished")

        _ = SDATaskRunner.runTaskUntilFinished(withCommandPath: commandPath,
                                               withArguments: nil,
                                               inDirectoryPath: nil) { (standardOutput, _, error) -> Void in

            XCTAssertNil(error)
            guard let standardOutput = standardOutput else {
                XCTAssertTrue(false)
                return
            }

            XCTAssertTrue(standardOutput.hasPrefix("Hello World"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testStandardLongFile() {
        let testDataPath = path(forResource: testDataHelloWorld,
                                ofType: testDataRubyFileExtension,
                                inDirectory: testDataSubdirectory)!

        let expectation = self.expectation(description: "Task finished")

        _ = SDATaskRunner.runTaskUntilFinished(withCommandPath: "/bin/cat",
                                               withArguments: [testDataPath as AnyObject],
                                               inDirectoryPath: nil) { (standardOutput, _, error) -> Void in

            XCTAssertNil(error)
            guard let standardOutput = standardOutput else {
                XCTAssertTrue(false)
                return
            }

            do {
                let testData = try String(contentsOfFile: testDataPath, encoding: String.Encoding.utf8)
                XCTAssertTrue(testData.isEqual(standardOutput))
            } catch let error as NSError {
                XCTAssertNil(error)
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
