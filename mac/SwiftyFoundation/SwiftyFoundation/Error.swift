import Foundation

extension NSError {

    convenience init(_ domain: String, _ code: Int, _ description: String) {
        self.init(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
}
