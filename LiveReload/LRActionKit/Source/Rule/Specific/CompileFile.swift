import Foundation
import ExpressiveCasting

public class CompileFileRule : ScriptInvocationRule {

    public var compilerName : String?

    public var outputFilterOption : FilterOption = try! FilterOption(memento: "subdir:.") {
        didSet {
            if outputFilterOption != oldValue {
                didChange();
            }
        }
    }

    public /*protected*/ override func loadFromMemento() throws {
        try super.loadFromMemento()
        compilerName = memento["compiler"]~~~
        outputFilterOption = try FilterOption(memento: memento["output"]~~~ ?? "subdir:.")
        intrinsicInputPathSpec = action.combinedIntrinsicInputPathSpec
    }

    public /*protected*/ override func updateMemento() {
        memento["output"] = outputFilterOption.memento
        super.updateMemento()
    }

    public func destinationFileForSourceFile(file: ProjectFile) -> ProjectFile? {
        guard let outputMaskString = NonEmptyStringValue(action.manifest["output"]) else {
            fatalError("output mask not specified for compilation action") // TODO: don't crash
        }

        guard let om = try? OutputMask(string: outputMaskString) else {
            fatalError("invalid output mask") // TODO: don't crash
        }

        guard let destinationPath = om.deriveOutputPathFromSourcePath(file.path, sourcePathSpec: intrinsicInputPathSpec!) else {
            return nil
        }

        // TODO: fix destination path mapping
//        let outputMappingIsRecursive = true  // TODO: make this conditional
//        if outputMappingIsRecursive {
//            let folderComponentCount = Int(inputFilterOption.directory.numberOfComponents)
//            if folderComponentCount > 0 {
//                let components = file.path.parent!.components
//                if components.count > folderComponentCount {
//                    destinationPath = components[folderComponentCount ..< components.count].joinWithSeparator("/").stringByAppendingPathComponent(destinationPath)
//                }
//            }
//        }
//        let destinationRelativePath = outputFilterOption.subfolder!.stringByAppendingPathComponent(destinationPath)

        return ProjectFile(path: destinationPath, project: project)
    }

    public override func handleDeletionOfFile(file: ProjectFile) {
        guard let destinationFile = destinationFileForSourceFile(file) else {
            return
        }

        if !destinationFile.isSameFile(file) && destinationFile.exists {
            try! NSFileManager.defaultManager().removeItemAtURL(destinationFile.absoluteURL)
        }
    }

    public override func configureStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        super.configureStep(step, forFile: file)

        step.addFileValue("src", file)

        guard let destinationFile = destinationFileForSourceFile(file) else {
            return
        }
        step.addFileValue("dst", destinationFile)

        let destinationFolderURL = destinationFile.absoluteURL.URLByDeletingLastPathComponent!
        if !destinationFolderURL.checkResourceIsReachableAndReturnError(nil) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(destinationFolderURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    public override func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        if let outputFile = step.fileForKey("dst") {
            file.project.hackhack_didWriteCompiledFile(outputFile)
        }
    }

    
    public override var supportsFileTargets : Bool {
        return true
    }

    public override func fileTargetForRootFile(file: ProjectFile) -> LRTarget? {
        return LRFileTarget(rule: self, sourceFile: file)
    }

}
