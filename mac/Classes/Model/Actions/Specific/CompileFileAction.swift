
import Foundation

@objc class CompileFileAction : ScriptInvocationAction {

    var compilerName : String?

    var outputFilterOption : FilterOption = FilterOption(memento: "subdir.") {
        didSet {
            if outputFilterOption != oldValue {
                didChange();
            }
        }
    }

    override var label : String {
        return type.name
    }

    override func loadFromMemento(memento: NSDictionary!) {
        super.loadFromMemento(memento)
        compilerName = memento["compiler"] as? String
        outputFilterOption = FilterOption(memento: NV(memento["output"] as? String, "subdir:."))
        intrinsicInputPathSpec = type.combinedIntrinsicInputPathSpec
    }

    override func updateMemento(memento: NSMutableDictionary!) {
        super.updateMemento(memento)
        memento["output"] = outputFilterOption.memento
    }

    func destinationFileForSourceFile(file: LRProjectFile, inProject project: Project) -> LRProjectFile {
        var destinationName = LRDeriveDestinationFileName(file.relativePath.lastPathComponent, type.manifest["output"]! as String, intrinsicInputPathSpec)

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

    override func handleDeletionOfFile(file: LRProjectFile!, inProject project: Project!) {
        let destinationFile = destinationFileForSourceFile(file, inProject: project)
        if (destinationFile.absoluteURL != file.absoluteURL) && destinationFile.exists {
            NSFileManager.defaultManager().removeItemAtURL(destinationFile.absoluteURL, error:nil)
        }
    }

    override func configureStep(step: ScriptInvocationStep!, forFile file: LRProjectFile!) {
        super.configureStep(step, forFile: file)

        step.addFileValue(file, forSubstitutionKey: "src")

        let destinationFile = destinationFileForSourceFile(file, inProject: step.project)
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

    override func fileTargetForRootFile(file: LRProjectFile!) -> LRTarget! {
        return LRFileTarget(action: self, sourceFile: file)
    }

}
