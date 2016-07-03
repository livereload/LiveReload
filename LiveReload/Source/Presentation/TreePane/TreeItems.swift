import Cocoa
import LRProjectKit
import Uniflow

public protocol TreeItem: class, Identifiable {

    var hasChildren: Bool { get }

    var children: [TreeItem] { get }

    var isExpandable: Bool { get }

    var isSelectable: Bool { get }

    var isGroupItem: Bool { get }

}

extension TreeItem {

    public var hasChildren: Bool {
        return !children.isEmpty
    }

    public var isExpandable: Bool {
        return hasChildren
    }

    public var isSelectable: Bool {
        return true
    }

    public var isGroupItem: Bool {
        return false
    }

}


//
//public class StaticTreeItem: TreeItem {
//
//    public let projectsHeader = ProjectsHeaderTreeItem()
//
//    public var children: [TreeItem] {
//        return [projectsHeader]
//    }
//
//}
//
//public class ProjectsHeaderTreeItem: TreeItem {
//
//    public var projectItems: [ProjectTreeItem] = [
//        ProjectTreeItem(project: Project(rootURL: NSURL.fileURLWithPath("/Users/andreyvit/dev"))),
//        ProjectTreeItem(project: Project(rootURL: NSURL.fileURLWithPath("/Users/andreyvit/Sites"))),
//    ]
//
//    public var children: [TreeItem] {
//        return projectItems.map { $0 as TreeItem }
//    }
//
//    public var isGroupItem: Bool {
//        return true
//    }
//
//}
//
//public class ProjectTreeItem: TreeItem {
//
//    public let project: Project
//
//    public init(project: Project) {
//        self.project = project
//    }
//
//    public var hasChildren: Bool {
//        return false
//    }
//
//    public var children: [TreeItem] {
//        return []
//    }
//
//}
