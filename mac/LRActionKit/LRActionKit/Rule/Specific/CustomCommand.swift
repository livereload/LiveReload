import Foundation
import SwiftyFoundation
import LRCommons

public class CustomCommandRule : Rule {

    public var command: String? {
        didSet {
            if (command != oldValue) {
                didChange()
            }
        }
    }

    public override var nonEmpty: Bool {
        return command != nil
    }

    public var singleLineCommand: String? {
        return command?.stringByReplacingOccurrencesOfString("\n", withString: "; ")
    }

    public override var label: String {
        if let command = singleLineCommand {
            return "Run \(command)"
        } else {
            return NSLocalizedString("Run custom command", comment: "")
        }
    }

    public class func keyPathsForValuesAffectingLabel() -> NSSet {
        return NSSet(object: "command")
    }

    public class func keyPathsForValuesAffectingNonEmpty() -> NSSet {
        return NSSet(object: "command")
    }

    public class func keyPathsForValuesAffectingSingleLineCommand() -> NSSet {
        return NSSet(object: "command")
    }

    public /*protected*/ override func loadFromMemento() {
        super.loadFromMemento()
        command = NonEmptyStringValue(memento["command"])
    }

    public /*protected*/ override func updateMemento() {
        super.updateMemento()
        memento["command"] = command ||| ""
    }

    public override func targetForModifiedFiles(files: [ProjectFile]) -> LRTarget? {
        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(rule: self, modifiedFiles: files as [ProjectFile])
        } else {
            return nil
        }
    }

    public override func invokeWithModifiedFiles(files: [ProjectFile], result: LROperationResult, completionHandler: dispatch_block_t) {
        let info = [
            "$(ruby)": "/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby",
            "$(node)": NSBundle.mainBundle().pathForResource("LiveReloadNodejs", ofType: nil)!,
            "$(project_dir)": project.rootURL.path
        ]
        // TODO: handle command being nil
        let command = self.command!.stringBySubstitutingValuesFromDictionary(info) as String
        let shell = "/bin/bash"

        let shArgs = ["-c", command]  // ["--login", "-i", "-c", command]

        let pwd = NSFileManager.defaultManager().currentDirectoryPath
        NSFileManager.defaultManager().changeCurrentDirectoryPath(project.rootURL.path)

        NSLog("Executing project rule command: %@", quotedArgumentStringUsingBourneQuotingStyle([shell] + shArgs));

        let shellUrl = NSURL.fileURLWithPath(shell)

        ATLaunchUnixTaskAndCaptureOutput(shellUrl, shArgs, .IgnoreSandbox | .MergeStdoutAndStderr, [ATCurrentDirectoryPathKey!: project.rootURL.path]) {
            (outputText: String!, stderrText: String?, error: NSError?) in
            NSFileManager.defaultManager().changeCurrentDirectoryPath(pwd)
            result.completedWithInvocationError(error, rawOutput: outputText, completionBlock: completionHandler)
        }
    }

}
