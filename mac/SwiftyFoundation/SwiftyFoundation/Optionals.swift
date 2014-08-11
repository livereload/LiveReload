import Foundation

extension Optional {

    func mapIf<U>(f: (T) -> U?) -> U? {
        if let v = self {
            return f(v)
        } else {
            return nil
        }
    }
    
}
