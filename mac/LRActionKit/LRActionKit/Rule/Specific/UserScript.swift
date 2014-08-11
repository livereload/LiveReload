import Foundation
import SwiftyFoundation

public class UserScriptRule : Rule {

    public var scriptName: String?

    public var script: UserScript? {
        if let actualScriptName = scriptName {
            let userScripts = UserScriptManager.sharedUserScriptManager().userScripts as [UserScript]
            if let matchingScript = findIf(userScripts, { $0.uniqueName == actualScriptName }) {
                return matchingScript
            } else {
                return MissingUserScript(name: actualScriptName)
            }
        } else {
            return nil;
        }
    }

    public override var label: String {
        return "Run \(scriptName)"
    }

    public class func keyPathsForValuesAffectingLabel() -> NSSet {
        return NSSet(object: "scriptName")
    }

    public class func keyPathsForValuesAffectingScript() -> NSSet {
        return NSSet(object: "scriptName")
    }

    public class func keyPathsForValuesAffectingNonEmpty() -> NSSet {
        return NSSet(object: "scriptName")
    }

    public override var nonEmpty: Bool {
        if scriptName == nil {
            return false
        } else if let actualScript = script {
            return actualScript.exists
        } else {
            return false
        }
    }

    public /*protected*/ override func loadFromMemento() {
        super.loadFromMemento()
//        scriptName = NonEmptyStringValue(memento["script"] as? String)
    }

    public /*protected*/ override func updateMemento() {
        super.updateMemento()
        memento["script"] = scriptName
    }

    public override func targetForModifiedFiles(files: [ProjectFile]) -> LRTarget? {
        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(rule: self, modifiedFiles: files as [ProjectFile])
        } else {
            return nil
        }
    }

    public override func invokeWithModifiedFiles(files: [ProjectFile], result: LROperationResult, completionHandler: dispatch_block_t) {
        let trueFiles = files as [ProjectFile]
        let filePaths = trueFiles.map { $0.relativePath }

        if let actualScript = script {
            actualScript.invokeForProjectAtPath(project.rootURL.path, withModifiedFiles:NSSet(array: filePaths), result: result, completionHandler: completionHandler)
        }
    }

}
