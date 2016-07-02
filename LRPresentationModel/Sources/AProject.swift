import Foundation

public protocol UniqueIdentifiable {

    var uniqueIdentifier: String { get }

}

public struct VFolder: UniqueObject {

    public let uniqueIdentifier: String

    public var displayName: String

    public var subfolders: [VFolder] = []

    public var rules: [ARule] = []

    public init(uniqueIdentifier: String, displayName: String) {
        self.uniqueIdentifier = uniqueIdentifier
        self.displayName = displayName
    }

}

public struct VRule: class, UniqueObject {

    var isTogglable: Bool { get }

    var dispayName: String { get }

}

public protocol AOption: class {
}

public struct VFolder: UniqueObject {

    public let uniqueIdentifier: String

    public var displayName: String

    public var subfolders: [VFolder] = []

    public var rules: [ARule] = []

    public init(uniqueIdentifier: String, displayName: String) {
        self.uniqueIdentifier = uniqueIdentifier
        self.displayName = displayName
    }
    
}
