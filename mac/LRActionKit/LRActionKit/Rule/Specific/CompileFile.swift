import Foundation
import SwiftyFoundation

public class CompileFileRule : ScriptInvocationRule {

    public var compilerName : String?

    public var outputFilterOption : FilterOption = FilterOption(memento: "subdir.") {
        didSet {
            if outputFilterOption != oldValue {
                didChange();
            }
        }
    }

    public /*protected*/ override func loadFromMemento() {
        super.loadFromMemento()
        compilerName = memento["compiler"]~~~
        outputFilterOption = FilterOption(memento: memento["output"] ~|||~ "subdir:.")
        intrinsicInputPathSpec = action.combinedIntrinsicInputPathSpec
    }

    public /*protected*/ override func updateMemento() {
        super.updateMemento()
        memento["output"] = outputFilterOption.memento
    }

    public func destinationFileForSourceFile(file: ProjectFile) -> ProjectFile {
        var destinationName = LRDeriveDestinationFileName(file.relativePath.lastPathComponent, action.manifest["output"]! as String, intrinsicInputPathSpec)

        var outputMappingIsRecursive = true  // TODO: make this conditional
        if outputMappingIsRecursive {
            let folderComponentCount = Int(inputFilterOption.folderComponentCount)
            if folderComponentCount > 0 {
                let components = file.relativePath.stringByDeletingLastPathComponent.pathComponents
                if components.count > folderComponentCount {
                    destinationName = join("/", components[folderComponentCount ..< components.count]).stringByAppendingPathComponent(destinationName)
                }
            }
        }

        let destinationRelativePath = outputFilterOption.subfolder!.stringByAppendingPathComponent(destinationName)
        return ProjectFile(relativePath: destinationRelativePath, project: project)
    }

    public override func handleDeletionOfFile(file: ProjectFile) {
        let destinationFile = destinationFileForSourceFile(file)
        if (destinationFile.absoluteURL != file.absoluteURL) && destinationFile.exists {
            NSFileManager.defaultManager().removeItemAtURL(destinationFile.absoluteURL, error:nil)
        }
    }

    public override func configureStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        super.configureStep(step, forFile: file)

        step.addFileValue(file, forSubstitutionKey: "src")

        let destinationFile = destinationFileForSourceFile(file)
        step.addFileValue(destinationFile, forSubstitutionKey: "dst")

        let destinationFolderURL = destinationFile.absoluteURL.URLByDeletingLastPathComponent!
        if !destinationFolderURL.checkResourceIsReachableAndReturnError(nil) {
            NSFileManager.defaultManager().createDirectoryAtURL(destinationFolderURL, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
    }

    public override func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        let outputFile = step.fileForKey("dst")
        file.project.hackhack_didWriteCompiledFile(outputFile)
    }

    
    public override var supportsFileTargets : Bool {
        return true
    }

    public override func fileTargetForRootFile(file: ProjectFile) -> LRTarget? {
        return LRFileTarget(rule: self, sourceFile: file)
    }

}
