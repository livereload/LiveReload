import Foundation

public protocol PathNode: class, CustomStringConvertible {

    var root: PathRoot { get }

    var parent: PathNode? { get }

    var pathString: String { get }

    var name: String { get }

    var isRoot: Bool { get }

    var isContainer: Bool { get }

    var numberOfComponents: Int { get }

}

public extension PathNode {

    public var description: String {
        return pathString
    }

    public var nameWithTrailingSeparator: String {
        if isContainer {
            if name.isEmpty {
                return ""
            } else {
                return name + PathSep
            }
        } else {
            return name
        }
    }

    public var pathString: String {
        if let parent = parent {
            return parent.pathString + nameWithTrailingSeparator
        } else {
            return nameWithTrailingSeparator
        }
    }

}
