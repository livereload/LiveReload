import Foundation

public class ActionSet: NSObject {

    public let project: ProjectContext
    public private(set) var actions: [Action] = []

    public init(project: ProjectContext) {
        self.project = project
    }

    public func addActions(newActions: [Action]) {
        actions.extend(newActions)
    }

}
