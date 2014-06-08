
import Foundation

class ScriptInvocationAction : Action {

    override func invokeWithModifiedFiles(files: LRProjectFile[], result: LROperationResult, completionHandler: dispatch_block_t) {
    }

    override func compileFile(file: LRProjectFile, result: LROperationResult, completionHandler: dispatch_block_t) {
        if !effectiveVersion {
            result.completedWithInvocationError(missingEffectiveVersionError)
            completionHandler()
            return
        }

        let step = ScriptInvocationStep()
        step.result = result
        configureStep(step, forFile: file)

        step.completionHandler = { step in
            self.didCompleteCompilationStep(step, forFile: file)
            completionHandler()
        }

        NSLog("%@: %@", self.label, file.absolutePath)
        step.invoke()
    }

    func configureStep(step: ScriptInvocationStep, forFile file: LRProjectFile) {
        configureStep(step)
    }

    func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: LRProjectFile) {
    }

}
