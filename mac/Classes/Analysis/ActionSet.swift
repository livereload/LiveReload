import Foundation

class ActionSet: NSObject {

    let project: Project
    var actions: Action[] = []

    init(project: Project) {
        self.project = project
    }

    func addActions(newActions: Action[]) {
        actions.extend(newActions)
    }

}
