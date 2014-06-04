
import Foundation

@objc class LRProjectTarget : LRTarget {

    var modifiedFiles: LRProjectFile[]

    init(action: Action, modifiedFiles: LRProjectFile[]) {
        self.modifiedFiles = modifiedFiles
        super.init(action: action)
    }

    override func invokeWithCompletionBlock(completionBlock: dispatch_block_t!, build: LRBuild!) {
        let result = self.newResult()
        action.invokeForProject(project, withModifiedFiles: modifiedFiles, result: result) {
            build.addOperationResult(result, forTarget: self, key:"\(self.project.path).postproc")
            completionBlock()
        }
    }

}
