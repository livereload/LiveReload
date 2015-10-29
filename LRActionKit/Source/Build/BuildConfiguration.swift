import Foundation
import ATPathSpec

public protocol BuildConfigurationProtocol {

    var forcedStylesheetReloadSpec: ATPathSpec? { get }

    var disableLiveRefresh: Bool { get }

}
