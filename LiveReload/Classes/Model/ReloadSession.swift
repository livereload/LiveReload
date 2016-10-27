import Foundation

private let liveExts: [String] = [".css", ".png", ".jpg", ".gif"]

private func isLiveRefreshPossible(path: String) -> Bool {
    for ext in liveExts {
        if path.hasSuffix(ext) {
            return true
        }
    }
    return false
}

public struct ReloadRequest {
    
    var path: String

    var originalPath: String
    
}

public class ReloadSession: NSObject {
    
    private var requests: [ReloadRequest] = []
    
    public private(set) var isLive = true

    public func add(path: String, originalPath: String) {
        if !isLiveRefreshPossible(path) {
            isLive = false
        }
        requests.append(ReloadRequest(path: path, originalPath: originalPath))
    }
    
    public var isEmpty: Bool {
        return requests.isEmpty
    }
    
    public func clear() {
        requests = []
        isLive = true
    }
    
}
