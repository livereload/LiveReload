import Foundation

public class CompileFolderRule : ScriptInvocationRule {

    public override func invokeWithModifiedFiles(files: [ProjectFile], result: LROperationResult, completionHandler: dispatch_block_t) {
        if effectiveVersion == nil {
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

    public override func targetForModifiedFiles(files: [ProjectFile]) -> LRTarget? {
        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(rule: self, modifiedFiles: files)
        } else {
            return nil
        }
    }

}
