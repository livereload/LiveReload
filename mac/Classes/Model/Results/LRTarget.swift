
import Foundation

@objc class LRTarget : NSObject {

    let rule : Rule

    var project : Project {
        return rule.project
    }

    init(rule: Rule) {
        self.rule = rule
    }

    func invoke(#build: LRBuild, completionBlock: dispatch_block_t) {
        fatalError("abstract")
    }

    func newResult() -> LROperationResult {
        let result = LROperationResult()
        rule.configureResult(result)
        return result
    }

}
