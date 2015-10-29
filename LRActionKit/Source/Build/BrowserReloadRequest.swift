import Foundation

public struct BrowserReloadRequest {

    public let changes: [BrowserChange]
    public let forceFullReload: Bool

    public init(changes: [BrowserChange], forceFullReload: Bool) {
        self.changes = changes
        self.forceFullReload = forceFullReload
    }

}

public struct BrowserChange {

    public let path: String

    public let localPath: String?

    public let originalPath: String?

    public init(path: String, localPath: String?, originalPath: String?) {
        self.path = path
        self.localPath = localPath
        self.originalPath = originalPath
    }

}
