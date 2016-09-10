import Foundation
import ATPathSpec
import ExpressiveCasting

public class FilterRule : ScriptInvocationRule {

    public override var supportsFileTargets: Bool {
        return true
    }

    public /*protected*/ override func loadFromMemento() throws {
        try super.loadFromMemento()

        let inputFilter = StringValue(action.manifest["input"])!
        intrinsicInputPathSpec = ATPathSpec(string: inputFilter, syntaxOptions: ATPathSpecSyntaxOptions.FlavorExtended)
    }

    public /*protected*/ override func updateMemento() {
        super.updateMemento()
    }

    public override func fileTargetForRootFile(file: ProjectFile) -> LRTarget? {
        return LRFileTarget(rule: self, sourceFile: file)
    }

    public override func configureStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        super.configureStep(step, forFile: file)
        step.addFileValue("src", file)
    }

    public override func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        let outputFile = step.fileForKey("src")!
        file.project.hackhack_didFilterFile(outputFile)
    }

    public override func compileFile(file: ProjectFile, result: LROperationResult, completionHandler: dispatch_block_t) {
        if (!project.hackhack_shouldFilterFile(file)) {
            completionHandler()
            return
        }

        super.compileFile(file, result: result, completionHandler: completionHandler)
    }

}
