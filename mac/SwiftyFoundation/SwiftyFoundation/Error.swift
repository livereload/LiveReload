import Foundation

public extension NSError {

    public convenience init(_ domain: String, _ code: Int, _ description: String) {
        self.init(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
}
