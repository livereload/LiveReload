//
//  LROperationResult.swift
//  LRActionKit
//
//  Created by Andrey Tarantsov on 2015-10-12.
//  Copyright © 2015 Andrey Tarantsov. All rights reserved.
//

import Foundation
import ExpressiveCasting
import MessageParsingKit

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
        return messages.filter { $0.severity == .Error || $0.severity == .Raw }
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

    public var messageSpecs: [MessagePattern] = []

    public func addMessage(message: LRMessage) {
        if message.severity == .Error {
            failed = true
        }
        messages.append(message)
    }

    public func addRawOutput(rawOutputChunk: String, withCompletionBlock completionBlock: dispatch_block_t) {
        rawOutput += rawOutputChunk

        if !rawOutputChunk.isEmpty {
            let (_, messages) = MessagePattern.parse(rawOutputChunk, using: messageSpecs)
            for message in messages {
                addMessage(LRMessage(message))
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
                addMessage(LRMessage(Message(severity: .Error, text: "Cannot launch compiler: \(e)", file: defaultMessageFile?.path.pathString)))
            } else {
                addMessage(LRMessage(Message(severity: .Raw, text: rawOutput, file: defaultMessageFile?.path.pathString)))
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


