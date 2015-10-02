import Foundation

public class LRProjectTarget : LRTarget {

    public let modifiedFiles: [ProjectFile]

    public init(rule: Rule, modifiedFiles: [ProjectFile]) {
        self.modifiedFiles = modifiedFiles
        super.init(rule: rule)
    }

    public override func invoke(build build: LRBuild, completionBlock: dispatch_block_t) {
        let result = self.newResult()
        rule.invokeWithModifiedFiles(modifiedFiles, result: result) {
            build.addOperationResult(result, forTarget: self, key:"\(self.project.path).postproc")
            completionBlock()
        }
    }

}
