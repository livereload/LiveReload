
import Foundation

@objc class LRProjectTarget : LRTarget {

    let modifiedFiles: LRProjectFile[]

    init(action: Action, modifiedFiles: LRProjectFile[]) {
        self.modifiedFiles = modifiedFiles
        super.init(action: action)
    }

    override func invoke(#build: LRBuild, completionBlock: dispatch_block_t) {
        let result = self.newResult()
        action.invokeWithModifiedFiles(modifiedFiles, result: result) {
            build.addOperationResult(result, forTarget: self, key:"\(self.project.path).postproc")
            completionBlock()
        }
    }

}
