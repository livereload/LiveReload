import Foundation
import PackageManagerKit

public class ActionSet: NSObject {

    public let project: ProjectContext

    public private(set) var actions: [Action] = []
    public private(set) var contextActions: [LRContextAction] = []

    private var actionsByIdentifier: [String: Action] = [:]
    private var contextActionsByIdentifier: [String: LRContextAction] = [:]

    public init(project: ProjectContext) {
        self.project = project
        super.init()
    }

    public func addActions(newActions: [Action]) {
        for action in newActions {
            addAction(action)
        }
    }

    public func addAction(action: Action) {
        actions.append(action)
        actionsByIdentifier[action.identifier] = action
        
        let contextAction = LRContextAction(action: action, project: project, resolutionContext: project.resolutionContext)
        contextActions.append(contextAction)
        contextActionsByIdentifier[action.identifier] = contextAction
    }
    
    public func findBoundAction(#actionIdentifier: String) -> LRContextAction? {
        return contextActionsByIdentifier[actionIdentifier]
    }
    
    public func findBoundAction(#action: Action) -> LRContextAction? {
        return findBoundAction(actionIdentifier: action.identifier)
    }

    public var resolutionContext: LRPackageResolutionContext {
        return project.resolutionContext
    }

}
