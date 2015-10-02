import Foundation

public class LRFileTarget : LRTarget {

    public let sourceFile: ProjectFile

    public init(rule: Rule, sourceFile: ProjectFile) {
        self.sourceFile = sourceFile
        super.init(rule: rule)
    }

    public override func invoke(build build: LRBuild, completionBlock: dispatch_block_t) {
        build.markAsConsumedByCompiler(sourceFile)
        if !sourceFile.exists {
            rule.handleDeletionOfFile(sourceFile)
            completionBlock()
        } else {
            let result = newResult()
            result.defaultMessageFile = sourceFile

            rule.compileFile(sourceFile, result: result) {
                if result.invocationError != nil {
                    NSLog("Error compiling \(self.sourceFile.relativePath): \(result.invocationError.domain) - \(result.invocationError.code) - \(result.invocationError.localizedDescription)")
                }
                build.addOperationResult(result, forTarget: self, key: "\(self.project.path).\(self.sourceFile.relativePath)")
                completionBlock()
            }
        }
    }

}
