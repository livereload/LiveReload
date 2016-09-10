import Foundation

private final class ChildPathNode: PathNode {

    private let _parent: PathNode
    let name: String
    let isContainer: Bool

    init(parent: PathNode, name: String, isContainer: Bool) {
        self._parent = parent
        self.name = name
        self.isContainer = isContainer
    }

    var parent: PathNode? {
        return _parent
    }

    var description: String {
        return pathString
    }

    var isRoot: Bool {
        return false
    }

    var root: PathRoot {
        return _parent.root
    }

    var numberOfComponents: Int {
        return _parent.numberOfComponents + 1
    }

}

public extension PathNode {

    public func childNamed(name: String, isContainer: Bool) -> PathNode {
        guard isContainer else {
            fatalError("childNamed called on a leaf PathNode \(self)")
        }
        return ChildPathNode(parent: self, name: name, isContainer: isContainer)
    }

}
