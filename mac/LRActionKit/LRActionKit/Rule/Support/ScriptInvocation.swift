import Foundation

public class ScriptInvocationRule : Rule {

    public override func invokeWithModifiedFiles(files: [ProjectFile], result: LROperationResult, completionHandler: dispatch_block_t) {
    }

    public override func compileFile(file: ProjectFile, result: LROperationResult, completionHandler: dispatch_block_t) {
        if effectiveVersion == nil {
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

    public func configureStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        configureStep(step)
    }

    public func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
    }

}
