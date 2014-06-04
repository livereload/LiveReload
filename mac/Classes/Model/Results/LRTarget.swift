
import Foundation

@objc class LRTarget : NSObject {

    let action : Action

    var project : Project {
        return action.project
    }

    init(action: Action) {
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
