import Foundation
import LRActionKit

@objc class LRProjectTarget : LRTarget {

    let modifiedFiles: [ProjectFile]

    init(rule: Rule, modifiedFiles: [ProjectFile]) {
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
