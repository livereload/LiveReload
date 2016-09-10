import Foundation

//public class SemanticVersionSpace: VersionSpace<SemanticVersion> {
//
//    public static let sharedInstance = SemanticVersionSpace()
//
//    public override func versionWithString(string: String) throws -> SemanticVersion {
//        return try SemanticVersion(string: string)
//    }
//
//    public override func versionWithComponents(major: Int, minor: Int) -> SemanticVersion {
//        return SemanticVersion(major, minor)
//    }
//
//}

public struct SemanticVersion: Version {

    public var major: Int = 0
    public var minor: Int = 0
    public var patch: Int = 0

    public var prereleaseIdentifiers: [String] = []
    public var buildIdentifiers: [String] = []

//    public var versionSpace: VersionSpace<SemanticVersion> {
//        return SemanticVersionSpace.sharedInstance
//    }

    public var prereleaseString: String? {
        get {
            if prereleaseIdentifiers.isEmpty {
                return nil
            } else {
                return prereleaseIdentifiers.joinWithSeparator(".")
            }
        }
        set {
            if let newValue = newValue {
                prereleaseIdentifiers = newValue.componentsSeparatedByString(".")
            } else {
                prereleaseIdentifiers = []
            }
        }
    }

    public var buildString: String? {
        get {
            if buildIdentifiers.isEmpty {
                return nil
            } else {
                return buildIdentifiers.joinWithSeparator(".")
            }
        }
        set {
            if let newValue = newValue {
                buildIdentifiers = newValue.componentsSeparatedByString(".")
            } else {
                buildIdentifiers = []
            }
        }
    }

    public init() {
    }

    public init(_ major: Int, _ minor: Int = 0, _ patch: Int = 0, prereleaseIdentifiers: [String] = [], buildIdentifiers: [String] = []) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prereleaseIdentifiers = prereleaseIdentifiers
        self.buildIdentifiers = buildIdentifiers
    }

    public init(string: String) throws {

    }

}

public func ==(lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    return true
}

public func <(lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    return true
}
