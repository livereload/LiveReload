
import Foundation

@objc class LRTarget : NSObject {

    let action : Rule

    var project : Project {
        return action.project
    }

    init(action: Rule) {
        self.action = action
    }

    func invoke(#build: LRBuild, completionBlock: dispatch_block_t) {
        fatalError("abstract")
    }

    func newResult() -> LROperationResult {
        let result = LROperationResult()
        action.configureResult(result)
        return result
    }

}
