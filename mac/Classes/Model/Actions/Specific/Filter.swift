
import Foundation

class FilterRule : ScriptInvocationRule {

    override var supportsFileTargets: Bool {
        return true
    }

    override func loadFromMemento() {
        super.loadFromMemento()

        let inputFilter = action.manifest["input"]! as String
        intrinsicInputPathSpec = ATPathSpec(string: inputFilter, syntaxOptions: ATPathSpecSyntaxOptions.FlavorExtended)
    }

    override func updateMemento() {
        super.updateMemento()
    }

    override func fileTargetForRootFile(file: LRProjectFile) -> LRTarget? {
        return LRFileTarget(rule: self, sourceFile: file)
    }

    override func configureStep(step: ScriptInvocationStep, forFile file: LRProjectFile) {
        super.configureStep(step, forFile: file)
        step.addFileValue(file, forSubstitutionKey: "src")
    }

    override func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: LRProjectFile) {
        let outputFile = step.fileForKey("src")!
        file.project.hackhack_didFilterFile(outputFile)
    }

    override func compileFile(file: LRProjectFile, result: LROperationResult, completionHandler: dispatch_block_t) {
        if (!project.hackhack_shouldFilterFile(file)) {
            completionHandler()
            return
        }

        super.compileFile(file, result: result, completionHandler: completionHandler)
    }

}
