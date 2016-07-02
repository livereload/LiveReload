import Cocoa
import LRProjectKit
import Uniflow

public class RootTreeItem: TreeItem {

//    public let identity = SimpleIdentity(Tag("RootTreeItem"))
    public var uniqueIdentifier: String {
        return String(self.dynamicType)
    }

    public let projectsHeader = ProjectsHeaderTreeItem()

    public var children: [TreeItem] {
        return [projectsHeader]
    }

//    public private(set) var isChanged: Bool = true
//    public func prepareForUpdateCycle() {
//        isChanged = false
//    }
//    public func update() {
//        for child in children {
//            child.update()
//        }
//    }

}

public class ProjectsHeaderTreeItem: TreeItem {

    public var uniqueIdentifier: String {
        return String(self.dynamicType)
    }

    public var projectItems: [ProjectTreeItem] = [
        ProjectTreeItem(project: Project(rootURL: NSURL.fileURLWithPath("/Users/andreyvit/dev"))),
        ProjectTreeItem(project: Project(rootURL: NSURL.fileURLWithPath("/Users/andreyvit/Sites"))),
    ]

    public var children: [TreeItem] {
        return projectItems.map { $0 as TreeItem }
    }

    public var isGroupItem: Bool {
        return true
    }

}

public class ProjectTreeItem: TreeItem {

    public var uniqueIdentifier: String {
        return project.uniqueIdentifier
    }

    public let project: Project

    public init(project: Project) {
        self.project = project
    }

    public var hasChildren: Bool {
        return false
    }

    public var children: [TreeItem] {
        return []
    }

}
