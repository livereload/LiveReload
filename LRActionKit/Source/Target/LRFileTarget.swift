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
                if let e = result.invocationError {
                    NSLog("Error compiling \(self.sourceFile.relativePath): \(e.domain) - \(e.code) - \(e.localizedDescription)")
                }
                build.addOperationResult(result, forTarget: self, key: "\(self.project.rootURL.path!).\(self.sourceFile.relativePath)")
                completionBlock()
            }
        }
    }

}
