
import Foundation

@objc class CompileFolderRule : ScriptInvocationRule {

    override var label : String {
        return type.name
    }

    override func invokeWithModifiedFiles(files: LRProjectFile[], result: LROperationResult, completionHandler: dispatch_block_t) {
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

    override func targetForModifiedFiles(files: LRProjectFile[]) -> LRTarget? {
        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(rule: self, modifiedFiles: files)
        } else {
            return nil
        }
    }

}
