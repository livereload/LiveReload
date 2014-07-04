
import Foundation

@objc class CompileFileRule : ScriptInvocationRule {

    var compilerName : String?

    var outputFilterOption : FilterOption = FilterOption(memento: "subdir.") {
        didSet {
            if outputFilterOption != oldValue {
                didChange();
            }
        }
    }

    override func loadFromMemento() {
        super.loadFromMemento()
        compilerName = stringValue(memento["compiler"])
        outputFilterOption = FilterOption(memento: NVCast(memento["output"], "subdir:."))
        intrinsicInputPathSpec = action.combinedIntrinsicInputPathSpec
    }

    override func updateMemento() {
        super.updateMemento()
        memento["output"] = outputFilterOption.memento
    }

    func destinationFileForSourceFile(file: LRProjectFile) -> LRProjectFile {
        var destinationName = LRDeriveDestinationFileName(file.relativePath.lastPathComponent, action.manifest["output"]! as String, intrinsicInputPathSpec)

        var outputMappingIsRecursive = true  // TODO: make this conditional
        if outputMappingIsRecursive {
            let folderComponentCount = inputFilterOption.folderComponentCount
            if folderComponentCount > 0 {
                let components = file.relativePath.stringByDeletingLastPathComponent.pathComponents
                if components.count > folderComponentCount {
                    destinationName = join("/", components[folderComponentCount .. components.count]).stringByAppendingPathComponent(destinationName)
                }
            }
        }

        let destinationRelativePath = outputFilterOption.subfolder!.stringByAppendingPathComponent(destinationName)
        return LRProjectFile(relativePath: destinationRelativePath, project: project)
    }

    override func handleDeletionOfFile(file: LRProjectFile) {
        let destinationFile = destinationFileForSourceFile(file)
        if (destinationFile.absoluteURL != file.absoluteURL) && destinationFile.exists {
            NSFileManager.defaultManager().removeItemAtURL(destinationFile.absoluteURL, error:nil)
        }
    }

    override func configureStep(step: ScriptInvocationStep!, forFile file: LRProjectFile!) {
        super.configureStep(step, forFile: file)

        step.addFileValue(file, forSubstitutionKey: "src")

        let destinationFile = destinationFileForSourceFile(file)
        step.addFileValue(destinationFile, forSubstitutionKey: "dst")

        let destinationFolderURL = destinationFile.absoluteURL.URLByDeletingLastPathComponent
        if !destinationFolderURL.checkResourceIsReachableAndReturnError(nil) {
            NSFileManager.defaultManager().createDirectoryAtURL(destinationFolderURL, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
    }

    override func didCompleteCompilationStep(step: ScriptInvocationStep!, forFile file: LRProjectFile!) {
        let outputFile = step.fileForKey("dst")
        file.project.hackhack_didWriteCompiledFile(outputFile)
    }

    
    override var supportsFileTargets : Bool {
        return true
    }

    override func fileTargetForRootFile(file: LRProjectFile) -> LRTarget? {
        return LRFileTarget(rule: self, sourceFile: file)
    }

}
