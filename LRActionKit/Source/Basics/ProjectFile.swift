import Foundation
import ATPathSpec

public class ProjectFile: NSObject {

    public let path: RelPath
    public let project: ProjectContext

    public init(path: RelPath, project: ProjectContext) {
        self.path = path
        self.project = project
    }

    public convenience init(relativePath: String, project: ProjectContext) {
        self.init(path: RelPath(relativePath, isDirectory: false), project: project)
    }

    public var relativePath: String {
        return path.pathString
    }

    public var absoluteURL: NSURL {
        return path.resolve(baseURL: project.rootURL)
    }

    public var absolutePath: String {
        return absoluteURL.path!
    }

    public var exists: Bool {
        return absoluteURL.checkResourceIsReachableAndReturnError(nil)
    }

    public override var description: String {
        return "File<\(relativePath)>"
    }

    public func isSameFile(other: ProjectFile) -> Bool {
        return (self.path == other.path) && (self.project === other.project)
    }

}
