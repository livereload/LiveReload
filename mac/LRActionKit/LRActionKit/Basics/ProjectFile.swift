import Foundation

public class ProjectFile: NSObject {

    public let relativePath: String
    public let project: ProjectContext

    public init(relativePath: String, project: ProjectContext) {
        self.relativePath = relativePath
        self.project = project
    }

    public var absoluteURL: NSURL {
        let rootURL: NSURL = project.rootURL
        return rootURL.URLByAppendingPathComponent(relativePath)
    }

    public var absolutePath: String {
        return absoluteURL.path
    }

    public var exists: Bool {
        return absoluteURL.checkResourceIsReachableAndReturnError(nil)
    }

    public override var description: String {
        return "File<\(relativePath)>"
    }

}
