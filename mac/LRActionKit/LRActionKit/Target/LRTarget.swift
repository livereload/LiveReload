
import Foundation

public class LRTarget : NSObject {

    public let rule : Rule

    public var project : Project {
        return rule.project
    }

    public init(rule: Rule) {
        self.rule = rule
    }

    public func invoke(#build: LRBuild, completionBlock: dispatch_block_t) {
        fatalError("abstract")
    }

    public func newResult() -> LROperationResult {
        let result = LROperationResult()
        rule.configureResult(result)
        return result
    }

}
