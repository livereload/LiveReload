import Foundation
import ATPathSpec

public class Deriver {
    
    public func deriveRules(fromTagTree tree: TagEvidenceTree, forActionSet actionSet: ActionSet) -> [Rule] {
        fatalError("Must override")
    }
    
}

public class CompileFileRuleDeriver : Deriver {
    
    public let action: Action
    
    public init(action: Action) {
        self.action = action
    }
    
    public override func deriveRules(fromTagTree tree: TagEvidenceTree, forActionSet actionSet: ActionSet) -> [Rule] {
        if let boundAction = actionSet.findBoundAction(action: action) {
            let folders = tree.findCoveringFoldersForTag(action.compilableFileTag!)
            return folders.map { self._createRule(relativeFolder: $0, boundAction: boundAction) }
        } else {
            return []
        }
    }
    
    private func _createRule(relativeFolder relativeFolder: String, boundAction: LRContextAction) -> Rule {
        return CompileFileRule(contextAction: boundAction, memento: ["action": boundAction.action.identifier, "filter": FilterOption(subfolder: relativeFolder).memento, "output": FilterOption(subfolder: relativeFolder).memento])
    }

}
