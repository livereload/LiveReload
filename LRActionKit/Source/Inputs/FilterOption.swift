import Foundation
import ExpressiveFoundation
import ExpressiveCasting
import ATPathSpec

public enum FilterOptionParseError: ErrorType {
    case UnsupportedMementoVersion
}

public final class FilterOption: Equatable {

    public let directory: RelPath
    public let pathSpec: ATPathSpec

    public init(directory: RelPath) {
        self.directory = directory
        pathSpec = ATPathSpec(matchingPath: directory, syntaxOptions: [.FlavorLiteral])
    }

    public convenience init(memento: String) throws {
        if let s = memento.removePrefixOrNil("subdir:") {
            let p: RelPath
            if s == "." {
                p = RelPath()
            } else {
                p = RelPath(s, isDirectory: true)
            }
            self.init(directory: p)
        } else {
            throw FilterOptionParseError.UnsupportedMementoVersion
        }
    }

    public var memento: String {
        let s: String
        if directory.numberOfComponents > 0 {
            s = directory.pathString
        } else {
            s = "."
        }
        return "subdir:" + s
    }

    public var displayName: String {
        return directory.pathString
    }

}

public func ==(lhs: FilterOption, rhs: FilterOption) -> Bool {
    return (lhs.directory == rhs.directory)
}
