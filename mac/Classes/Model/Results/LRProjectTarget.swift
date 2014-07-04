
import Foundation

@objc class LRProjectTarget : LRTarget {

    let modifiedFiles: LRProjectFile[]

    init(rule: Rule, modifiedFiles: LRProjectFile[]) {
        self.modifiedFiles = modifiedFiles
        super.init(rule: rule)
    }

    override func invoke(#build: LRBuild, completionBlock: dispatch_block_t) {
        let result = self.newResult()
        rule.invokeWithModifiedFiles(modifiedFiles, result: result) {
            build.addOperationResult(result, forTarget: self, key:"\(self.project.path).postproc")
            completionBlock()
        }
    }

}
