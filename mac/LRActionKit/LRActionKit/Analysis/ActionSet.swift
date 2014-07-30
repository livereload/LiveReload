import Foundation

public class ActionSet: NSObject {

    public  let project: Project
    var actions: [Action] = []

    public init(project: Project) {
        self.project = project
    }

    public func addActions(newActions: [Action]) {
        actions.extend(newActions)
    }

}
