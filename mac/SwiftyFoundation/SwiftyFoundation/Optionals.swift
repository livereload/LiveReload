import Foundation

// "object OR"
operator infix ||| {}

@infix public func ||| <T> (optional: T?, defaultValue: @auto_closure () -> T) -> T {
    if let unwrapped = optional {
        return unwrapped
    } else {
        return defaultValue()
    }
}

extension Optional {

    func mapIf<U>(f: (T) -> U?) -> U? {
        if let v = self {
            return f(v)
        } else {
            return nil
        }
    }
    
}
