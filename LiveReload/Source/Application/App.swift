import Foundation
import LRProjectKit

public class App {

    public let workspace = Workspace()

    internal init() {
        workspace.projects.add(NSURL.fileURLWithPath("/Users/andreyvit/dev", isDirectory: true))
        workspace.projects.add(NSURL.fileURLWithPath("/Users/andreyvit/Sites", isDirectory: true))
    }

    public func dispose() {
        workspace.dispose()
    }

}
