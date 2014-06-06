
import Foundation

// the name is referenced in plugin manifest
@objc(UserScriptAction)
class UserScriptAction : Action {

    var scriptName: String?

    var script: UserScript? {
        if let actualScriptName = scriptName {
            let userScripts = UserScriptManager.sharedUserScriptManager().userScripts as UserScript[]
            if let matchingScript = findWhere(userScripts, { $0.uniqueName == actualScriptName }) {
                return matchingScript
            } else {
                return MissingUserScript(name: actualScriptName)
            }
        } else {
            return nil;
        }
    }

    override var label: String {
        return "Run \(scriptName)"
    }

    class func keyPathsForValuesAffectingLabel() -> NSSet {
        return NSSet(object: "scriptName")
    }

    class func keyPathsForValuesAffectingScript() -> NSSet {
        return NSSet(object: "scriptName")
    }

    class func keyPathsForValuesAffectingNonEmpty() -> NSSet {
        return NSSet(object: "scriptName")
    }

    override var nonEmpty: Bool {
        if !scriptName {
            return false
        } else if let actualScript = script {
            return actualScript.exists
        } else {
            return false
        }
    }

    override func loadFromMemento(memento: NSDictionary!) {
        super.loadFromMemento(memento)
//        scriptName = EmptyToNil(memento["script"] as? String)
    }

    override func updateMemento(memento: NSMutableDictionary!) {
        super.updateMemento(memento)
        memento["script"] = scriptName
    }

    override func targetForModifiedFiles(files: AnyObject[]!) -> LRTarget! {
        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(action: self, modifiedFiles: files as LRProjectFile[])
        } else {
            return nil
        }
    }

    override func invokeWithModifiedFiles(files: AnyObject[]!, result: LROperationResult!, completionHandler: dispatch_block_t!) {
        let trueFiles = files as LRProjectFile[]
        let filePaths = trueFiles.map { $0.relativePath }

        if let actualScript = script {
            actualScript.invokeForProjectAtPath(project.rootURL.path, withModifiedFiles:NSSet(array: filePaths), result: result, completionHandler: completionHandler)
        }
    }

}
