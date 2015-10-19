//
//  LROperationResult.swift
//  LRActionKit
//
//  Created by Andrey Tarantsov on 2015-10-12.
//  Copyright © 2015 Andrey Tarantsov. All rights reserved.
//

import Foundation
import ExpressiveCasting

public class LROperationResult: NSObject, UserScriptResult {

    public private(set) var completed: Bool = false

    // either an error message is logged, or an error is indicated by the exit code
    public private(set) var failed: Bool = false

    public private(set) var invocationError: NSError?

    // error indicated by the exit code, but no error messages detected
    public var parsingFailed: Bool {
        return failed && !rawOutput.isEmpty && errors.isEmpty
    }

    public private(set) var messages: [LRMessage] = []

    public var errors: [LRMessage] {
        return messages.filter { $0.severity == .Error }
    }

    public var warnings: [LRMessage] {
        return messages.filter { $0.severity == .Warning }
    }

    public private(set) var rawOutput: String = ""

    //@property (nonatomic, copy, readonly) NSArray *messages;
    //@property (nonatomic, copy, readonly) NSArray *errors;
    //@property (nonatomic, copy, readonly) NSArray *warnings;
    //
    //@property (nonatomic, copy, readonly) NSString *rawOutput;

    public var defaultMessageFile: ProjectFile?

    public var errorSyntaxManifest: JSONObject?

    public func addMessage(message: LRMessage) {
        if message.severity == .Error {
            failed = true
        }
        messages.append(message)
    }

    public func addRawOutput(rawOutputChunk: String, withCompletionBlock completionBlock: dispatch_block_t) {
        rawOutput += rawOutputChunk

        if !rawOutputChunk.isEmpty {
            if let errorSyntaxManifest = errorSyntaxManifest {
                let m: JSONObject = ["service": "msgparser", "command": "parse", "manifest": errorSyntaxManifest, "input": rawOutputChunk]
                ActionKitSingleton.sharedActionKit.postMessage(m, completionBlock: { error, response in
                    if let response = response {
                        for message in JSONObjectsArrayValue(response["messages"]) ?? [] {
//                            let type = message["type"]~~~ ?? ""
                            let severityString = message["severity"]~~~ ?? ""
                            let severity: LRMessageSeverity = (severityString == "error" ? .Error : .Warning)
                            let text = message["message"]~~~ ?? ""
                            let affectedFilePath = message["file"]~~~ ?? (self.defaultMessageFile?.absolutePath ?? "")
                            let line = message["line"]~~~ ?? 0
                            let column = message["column"]~~~ ?? 0
                            let message = LRMessage(severity: severity, text: text, filePath: affectedFilePath, line: line, column: column)
                            self.addMessage(message)
                        }
                    }
                    completionBlock()
                })
                return
            }
        }

        completionBlock()
    }

    public func completedWithInvocationError(error: NSError?) {
        completed = true

        if error != nil {
            failed = true
        }

        if failed && messages.isEmpty {
            if rawOutput.isEmpty {
                let e = error?.localizedDescription ?? ""
                addMessage(LRMessage(severity: .Error, text: "Cannot launch compiler: \(e)", filePath: defaultMessageFile?.path.pathString, line: 0, column: 0))
            } else {
                let m = LRMessage(severity: .Error, text: rawOutput, filePath: defaultMessageFile?.path.pathString, line: 0, column: 0)
                m.rawOutput = rawOutput
                addMessage(m)
            }
        }

        invocationError = error
    }

    public func completedWithInvocationError(error: NSError?, rawOutput chunk: String, withCompletionBlock completionBlock: dispatch_block_t) {
        addRawOutput(chunk) {
            self.completedWithInvocationError(error)
            completionBlock()
        }
    }

}


