import Foundation

class LRProjectFile: NSObject {

    let relativePath: String
    let project: Project

    init(relativePath: String, project: Project) {
        self.relativePath = relativePath
        self.project = project
    }

    var absoluteURL: NSURL {
        let rootURL: NSURL = project.rootURL
        return rootURL.URLByAppendingPathComponent(relativePath)
    }

    var absolutePath: String {
        return absoluteURL.path
    }

    var exists: Bool {
        return absoluteURL.checkResourceIsReachableAndReturnError(nil)
    }

    override var description: String {
        return "File<\(relativePath)"
    }

}
