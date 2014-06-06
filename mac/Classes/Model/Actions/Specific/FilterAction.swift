
import Foundation

@objc(FilterAction)
class FilterAction : ScriptInvocationAction {

    override var label: String {
        return type.name
    }

    override var supportsFileTargets: Bool {
        return true
    }

    override func loadFromMemento(memento: NSDictionary!) {
        super.loadFromMemento(memento)

        let inputFilter = type.manifest["input"]! as String
        intrinsicInputPathSpec = ATPathSpec(string: inputFilter, syntaxOptions: ATPathSpecSyntaxFlavorExtended)
    }

    override func updateMemento(memento: NSMutableDictionary!) {
        super.updateMemento(memento)
    }

    override func fileTargetForRootFile(file: LRProjectFile!) -> LRTarget! {
        return LRFileTarget(action: self, sourceFile: file)
    }

    override func configureStep(step: ScriptInvocationStep, forFile file: LRProjectFile) {
        super.configureStep(step, forFile: file)
        step.addFileValue(file, forSubstitutionKey: "src")
    }

    override func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: LRProjectFile) {
        let outputFile = step.fileForKey("src")!
        file.project.hackhack_didFilterFile(outputFile)
    }

    override func compileFile(file: LRProjectFile!, inProject project: Project!, result: LROperationResult!, completionHandler: dispatch_block_t!) {
        if (!project.hackhack_shouldFilterFile(file)) {
            completionHandler()
            return
        }

        super.compileFile(file, inProject: project, result: result, completionHandler: completionHandler)
    }

}
