import Foundation
import PackageManagerKit

public class ActionSet: NSObject {

    public unowned let project: ProjectContext

    public private(set) var actions: [Action] = []
    public private(set) var contextActions: [LRContextAction] = []

    private var actionsByIdentifier: [String: Action] = [:]
    private var contextActionsByIdentifier: [String: LRContextAction] = [:]

    public init(project: ProjectContext) {
        self.project = project
        super.init()
    }

    public func replaceActions(newActions: [Action]) {
        let oldContextActionsByIdentifier = contextActionsByIdentifier

        actions = []
        contextActions = []
        actionsByIdentifier = [:]
        contextActionsByIdentifier = [:]
        
        for action in newActions {
            addAction(action, reusing: oldContextActionsByIdentifier[action.identifier])
        }
    }
 
    public func addAction(action: Action) {
    }

    private func addAction(action: Action, reusing contextAction: LRContextAction?) {
        actions.append(action)
        actionsByIdentifier[action.identifier] = action
        
        let contextAction = contextAction ?? LRContextAction(action: action, project: project, resolutionContext: project.resolutionContext)
        contextActions.append(contextAction)
        contextActionsByIdentifier[action.identifier] = contextAction
    }
    
    public func findBoundAction(actionIdentifier actionIdentifier: String) -> LRContextAction? {
        return contextActionsByIdentifier[actionIdentifier]
    }
    
    public func findBoundAction(action action: Action) -> LRContextAction? {
        return findBoundAction(actionIdentifier: action.identifier)
    }

    public var resolutionContext: LRPackageResolutionContext {
        return project.resolutionContext
    }

}
