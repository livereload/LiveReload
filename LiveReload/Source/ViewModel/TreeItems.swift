import Cocoa
import LRProjectKit

public protocol TreeItem: class {

    var hasChildren: Bool { get }

    var children: [TreeItem] { get }

    var isExpandable: Bool { get }

    var isSelectable: Bool { get }

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

}

public class RootTreeItem: TreeItem {

    public let projectsHeader = ProjectsHeaderTreeItem()

    public var children: [TreeItem] {
        return [projectsHeader]
    }

}

public class ProjectsHeaderTreeItem: TreeItem {

    public var projectItems: [ProjectTreeItem] = []

    public var children: [TreeItem] {
        return projectItems.map { $0 as TreeItem }
    }

}

public class ProjectTreeItem: TreeItem {

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
