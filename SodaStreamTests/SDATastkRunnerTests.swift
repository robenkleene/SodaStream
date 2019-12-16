//
//  SDATastkRunnerTests.swift
//  SodaStreamTests
//
//  Created by Roben Kleene on 7/30/19.
//  Copyright © 2019 Roben Kleene. All rights reserved.
//

@testable import SodaStream
import XCTest

class RunResult: NSObject, SDATaskRunnerDelegate {
    var commandPath: String?
    var arguments: [String]?
    var directoryPath: String?
    var environmentDictionary: [String: String]?
    var error: Error?
    var standardOutput: String?
    var standardError: String?
    var standardOutputCompletionHandler: (() -> Void)?
    func task(_: Process,
              didFailToRunCommandPath commandPath: String,
              arguments: [String]?,
              directoryPath: String?,
              withEnvironment environmentDictionary: [String: String]?,
              error: Error) {
        self.commandPath = commandPath
        self.arguments = arguments
        self.directoryPath = directoryPath
        self.environmentDictionary = environmentDictionary
        self.error = error
    }

    func task(_: Process,
              didRunCommandPath commandPath: String,
              arguments: [String]?,
              directoryPath: String?,
              withEnvironment environmentDictionary: [String: String]?) {
        self.commandPath = commandPath
        self.arguments = arguments
        self.directoryPath = directoryPath
        self.environmentDictionary = environmentDictionary
    }

    func task(_: Process, didReadFromStandardError text: String) {
        standardError = text
    }

    func task(_: Process, didReadFromStandardOutput text: String) {
        standardOutput = text
        guard let standardOutputCompletionHandler = standardOutputCompletionHandler else {
            return
        }
        standardOutputCompletionHandler()
    }
}

class SDATastkRunnerTests: XCTestCase {
    func testStandardOutput() {
        let runResult = RunResult()
        let commandPath = path(forResource: testDataHelloWorld,
                               ofType: testDataShellScriptExtension,
                               inDirectory: testDataSubdirectory)!

        let finishedExpectation = expectation(description: "Task finished")
        let outputExpectation = expectation(description: "Output expectation")

        SDATaskRunner.runTask(withCommandPath: commandPath,
                              withArguments: nil,
                              inDirectoryPath: nil,
                              withEnvironment: nil,
                              delegate: runResult) { success, _ in
            XCTAssertTrue(success)
            XCTAssertEqual(runResult.commandPath, commandPath)
            XCTAssertNil(runResult.error)
            XCTAssertNil(runResult.arguments)
            XCTAssertNil(runResult.directoryPath)
            XCTAssertNil(runResult.environmentDictionary)
            finishedExpectation.fulfill()
        }

        runResult.standardOutputCompletionHandler = {
            guard let standardOutput = runResult.standardOutput else {
                XCTFail()
                return
            }
            XCTAssertTrue(standardOutput.hasPrefix("Hello World"))
            outputExpectation.fulfill()
        }
        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testInvalidCommandPath() {
        let runResult = RunResult()
        let commandPath = "invalid path"
        let failExpectation = expectation(description: "Run failure")

        SDATaskRunner.runTask(withCommandPath: commandPath,
                              withArguments: nil,
                              inDirectoryPath: nil,
                              withEnvironment: nil,
                              delegate: runResult) { success, _ in
            XCTAssertFalse(success)
            XCTAssertEqual(runResult.commandPath, commandPath)
            XCTAssertNil(runResult.arguments)
            XCTAssertNil(runResult.directoryPath)
            XCTAssertNil(runResult.environmentDictionary)
            XCTAssertNotNil(runResult.error)
            failExpectation.fulfill()
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }

    func testEnvironment() {
        let runResult = RunResult()
        let commandPath = path(forResource: testDataEchoMessage,
                               ofType: testDataShellScriptExtension,
                               inDirectory: testDataSubdirectory)!
        let environment = [testDataMessageKey: testDataMessageText]

        let finishedExpectation = expectation(description: "Task finished")
        let outputExpectation = expectation(description: "Output expectation")

        runResult.standardOutputCompletionHandler = {
            guard let standardOutput = runResult.standardOutput else {
                XCTFail()
                return
            }
            XCTAssertTrue(standardOutput.hasPrefix("A message"))
            outputExpectation.fulfill()
        }

        SDATaskRunner.runTask(withCommandPath: commandPath,
                              withArguments: nil,
                              inDirectoryPath: nil,
                              withEnvironment: environment,
                              delegate: runResult) { success, _ in
            XCTAssertTrue(success)
            XCTAssertEqual(runResult.commandPath, commandPath)
            XCTAssertNil(runResult.error)
            XCTAssertNil(runResult.arguments)
            XCTAssertNil(runResult.directoryPath)
            guard let environmentDictionary = runResult.environmentDictionary else {
                XCTFail()
                return
            }
            XCTAssertEqual(runResult.environmentDictionary, environmentDictionary)
            finishedExpectation.fulfill()
        }

        waitForExpectations(timeout: testTimeout, handler: nil)
    }
}
