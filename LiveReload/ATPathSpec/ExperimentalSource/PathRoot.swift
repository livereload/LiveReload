import Foundation

public let DefaultPathRoot = AnonymousPathRoot(debugName: "default")

public protocol PathRoot: PathNode {
}

public extension PathRoot {

    public var root: PathRoot {
        return self
    }

    public var parent: PathNode? {
        return nil
    }

    public var isRoot: Bool {
        return true
    }

    public var isContainer: Bool {
        return true
    }

}

public final class AnonymousPathRoot: PathRoot {

    public let debugName: String

    private init(debugName: String) {
        self.debugName = debugName
    }

    public var name: String {
        return ""
    }

    public var description: String {
        return "(\(debugName))"
    }

    public var numberOfComponents: Int {
        return 0
    }
    
}

public class NamedPathRoot: PathRoot {

    public let name: String

    public init(name: String) {
        self.name = name
    }

    public var description: String {
        return name
    }

    public var pathString: String {
        return name + PathSep
    }

    public var numberOfComponents: Int {
        return 1
    }

}
