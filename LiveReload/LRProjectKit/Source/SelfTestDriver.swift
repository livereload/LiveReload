import ExpressiveFoundation
import Cocoa
import ATPathSpec

public class SelfTest {

    public struct Options: OptionSetType {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let None: Options = []
        public static let Legacy = Options(rawValue: 0)

    }

    public let directoryURL: NSURL
    private let manifestURL: NSURL

    public init(directoryURL: NSURL, options: Options) {
        self.directoryURL = directoryURL
        manifestURL = directoryURL.URLByAppendingPathComponent("livereload-test.json")
        loadManifest()
    }

    public var completionBlock: (() -> Void)?

    public func run() {
    }

    private func loadManifest() {

    }

}
