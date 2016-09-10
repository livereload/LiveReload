import Foundation

private let DOT_CHARSET = NSCharacterSet(charactersInString: ".")

//public struct PathComponent: Equatable, Comparable, CustomStringConvertible {
//
//    public var name: String
//
//    public init(_ name: String) {
//        self.name = name
//    }
//
////    public init(stringLiteral value: StringLiteralType) {
////        self.init(value as String)
////    }
////
////    public init(extendedGraphemeClusterLiteral value: Swift.ExtendedGraphemeClusterLiteralType) {
////        self.init(value)
////    }
////
////    public init(unicodeScalarLiteral value: Swift.UnicodeScalarLiteralType) {
////        self.init(value)
////    }
//
//    public var description: String {
//        return name
//    }
//
//}
//
//public func ==(lhs: PathComponent, rhs: PathComponent) -> Bool {
//    return (lhs.name == rhs.name)
//}
//
//public func <(lhs: PathComponent, rhs: PathComponent) -> Bool {
//    return (lhs.name < rhs.name)
//}

public struct RelPath: CustomStringConvertible {

    public var components: [String]
    public var isDirectory: Bool?

    // ‘designated initializer’
    public init(components: [String], isDirectory: Bool?) {
        self.components = components
        self.isDirectory = isDirectory
    }

    public init() {
        self.init(components: [], isDirectory: true)
    }

    public init(name: String) {
        let isDirectory = name.hasSuffix(PathSep)
        self.init(components: [name], isDirectory: isDirectory)
    }

    public init(name: String, isDirectory: Bool?) {
        self.init(components: [name], isDirectory: isDirectory)
    }

    public init(_ string: String, isDirectory: Bool? = nil) {
        let c = string.componentsSeparatedByString(PathSep).filter { !$0.isEmpty }
        self.init(components: c, isDirectory: isDirectory)
    }

    public init(_ string: String) {
        let c = string.componentsSeparatedByString(PathSep).filter { !$0.isEmpty }
        let isDirectory = (string.hasSuffix("/") || c.isEmpty)
        self.init(components: c, isDirectory: isDirectory)
    }

    public var numberOfComponents: Int {
        return components.count
    }

    public var pathString: String {
        let s = components.joinWithSeparator(PathSep)
        if let isDirectory = isDirectory {
            if isDirectory {
                return s + PathSep
            }
        }
        return s
    }

    public var description: String {
        return pathString
    }

    public var isEmpty: Bool {
        return components.isEmpty
    }

    public var lastComponent: String? {
        return components.last
    }

}


// MARK: - Parents

public extension RelPath {

    public var hasParent: Bool {
        return components.count > 0
    }

    public var hasMultipleComponents: Bool {
        return components.count > 1
    }

    public var parent: RelPath? {
        if hasParent {
            let c = components[0 ..< components.count - 1]
            return RelPath(components: Array(c), isDirectory: true)
        } else {
            return nil
        }
    }

}


// MARK: - Comparison and hash

extension RelPath: Equatable {}

public func ==(lhs: RelPath, rhs: RelPath) -> Bool {
    return (lhs.components == rhs.components) && (lhs.isDirectory == rhs.isDirectory)
}

extension RelPath: Hashable {

    public var hashValue: Int {
        // see http://stackoverflow.com/questions/31438210/how-to-implement-the-hashable-protocol-in-swift-for-an-int-array-a-custom-strin

        var hash = 5381
        for component in components {
            hash = ((hash << 5) &+ hash) &+ component.hashValue
        }

        hash = ((hash << 5) &+ hash) &+ entryType.hashValue

        return hash
    }

}


// MARK: - Concatenation

public extension RelPath {

    public func childNamed(name: String, isDirectory: Bool?) -> RelPath {
        return self + RelPath(name: name, isDirectory: isDirectory)
    }

    public func childNamed(name: String) -> RelPath {
        return self + RelPath(name: name)
    }

}

public func +(lhs: RelPath, rhs: RelPath) -> RelPath {
    if let parentIsDirectory = lhs.isDirectory {
        if !parentIsDirectory {
            fatalError("Trying to add components (\(rhs)) to a leaf path (\(lhs))")
        }
    }
    return RelPath(components: lhs.components + rhs.components, isDirectory: rhs.isDirectory)
}


// MARK: NSURL

public extension RelPath {

    public func resolve(baseURL baseURL: NSURL) -> NSURL {
        let s = pathString
        if let isDirectory = isDirectory {
            if #available(OSX 10.11, *) {
                return NSURL(fileURLWithPath: s, isDirectory: isDirectory, relativeToURL: baseURL)
            } else {
                return baseURL.URLByAppendingPathComponent(s, isDirectory: isDirectory)
            }
        } else {
            if #available(OSX 10.11, *) {
                return NSURL(fileURLWithPath: s, relativeToURL: baseURL)
            } else {
                return baseURL.URLByAppendingPathComponent(s)
            }
        }
    }

}


// MARK: - Path extension

public extension RelPath {

    public static func addLeadingDot(ext: String) -> String {
        if ext.hasPrefix(".") || ext.isEmpty {
            return ext
        } else {
            return "." + ext
        }
    }

    public func hasPathExtension(ext: String) -> Bool {
        if let c = lastComponent {
            if ext.isEmpty {
                // TODO: what should this return for an empty extension?
                return false
            } else {
                return c.hasSuffix(RelPath.addLeadingDot(ext))
            }
        } else {
            return false
        }
    }

    public var pathExtensionCandidates: [String] {
        if let c = lastComponent {
            var result: [String] = []
            var range = Range(start: c.startIndex, end: c.endIndex)
            while !range.isEmpty {
                if let m = c.rangeOfCharacterFromSet(DOT_CHARSET, options: [.BackwardsSearch], range: range) {
                    let ext = c.substringFromIndex(m.startIndex.successor())
                    result.append(ext)
                    range.endIndex = m.startIndex
                } else {
                    break
                }
            }
            return result
        } else {
            return []
        }
    }

    public var shortestPathExtension: String? {
        if let c = lastComponent {
            if let m = c.rangeOfCharacterFromSet(DOT_CHARSET, options: [.BackwardsSearch], range: nil) {
                return c.substringFromIndex(m.startIndex.successor())
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    public func replaceSuffix(oldSuffix: String, _ newSuffix: String) -> (RelPath, Bool) {
        var cc = components
        if var c = cc.last where c.replaceSuffixInPlace(oldSuffix, newSuffix) {
            cc.removeLast()
            cc.append(c)
            return (RelPath(components: cc, isDirectory: isDirectory), true)
        } else {
            return (self, false)
        }
    }

    public func replacePathExtension(oldExt: String, _ newExt: String) -> (RelPath, Bool) {
        return replaceSuffix(RelPath.addLeadingDot(oldExt), RelPath.addLeadingDot(newExt))
    }

    public func replaceShortestPathExtensionWith(newExt: String) -> (RelPath, Bool) {
        return replacePathExtension(shortestPathExtension ?? "", newExt)
    }

}


// MARK: ATPathSpec interop

public extension RelPath {

    public var entryType: ATPathSpecEntryType {
        if let isDirectory = isDirectory {
            if isDirectory {
                return .Folder
            } else {
                return .File
            }
        } else {
            return .FileOrFolder
        }
    }

}

public enum Match {

    case Included
    case Excluded

    public static func from(result: ATPathSpecMatchResult) -> Match? {
        switch result {
        case .Unknown:
            return nil
        case .Matched:
            return .Included
        case .Excluded:
            return .Excluded
        }
    }

}

public struct PathMatchDetails {

    public let matchedSuffix: String?
    public let matchedStaticName: String?

    private init(dictionary: [String: AnyObject]) {
        matchedSuffix = dictionary[ATPathSpecMatchInfoMatchedSuffix] as? String
        matchedStaticName = dictionary[ATPathSpecMatchInfoMatchedStaticName] as? String
    }

}

public extension ATPathSpec {

    public convenience init(matchingPath path: RelPath, syntaxOptions: ATPathSpecSyntaxOptions) {
        self.init(matchingPath: path.pathString, type: path.entryType, syntaxOptions: syntaxOptions)
    }

    public func match(path: RelPath) -> Match? {
        let r = matchResultForPath(path.pathString, type: path.entryType, matchInfo: nil)
        return Match.from(r)
    }

    public func includes(path: RelPath) -> Bool {
        return match(path) == .Some(.Included)
    }

    public func excludes(path: RelPath) -> Bool {
        return match(path) == .Some(.Excluded)
    }

    public func matchWithDetails(path: RelPath) -> (Match, PathMatchDetails)? {
        var raw: NSDictionary?
        let r = matchResultForPath(path.pathString, type: path.entryType, matchInfo: &raw)
        if let m = Match.from(r) {
            let details = PathMatchDetails(dictionary: raw as! [String: AnyObject])
            return (m, details)
        } else {
            return nil
        }
    }

    public func includesWithDetails(path: RelPath) -> PathMatchDetails? {
        if let (match, details) = matchWithDetails(path) where match == .Included {
            return details
        } else {
            return nil
        }
    }

    public func filterMatchingPaths(paths: [RelPath]) -> [RelPath] {
        return paths.filter { includes($0) }
    }

}
