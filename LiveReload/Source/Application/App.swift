import Foundation
import LRProjectKit

public class App {

    public let workspace = Workspace()

    internal init() {
    }

    public func dispose() {
        workspace.dispose()
    }

}
