
import Foundation

@objc class CompileFolderAction : ScriptInvocationAction {

    override var label : String {
        return type.name
    }

    override func invokeWithModifiedFiles(files: AnyObject[], result: LROperationResult, completionHandler: dispatch_block_t!) {
        if !effectiveVersion {
            result.completedWithInvocationError(missingEffectiveVersionError)
            completionHandler()
            return
        }

        let step = ScriptInvocationStep()
        step.result = result
        configureStep(step)

        step.completionHandler = { (step) in
            completionHandler()
        }

        step.invoke()
    }

    override func targetForModifiedFiles(untypedFiles: AnyObject[]) -> LRTarget? {
        let files = untypedFiles as LRProjectFile[]

        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(action: self, modifiedFiles: files)
        } else {
            return nil
        }
    }

}
