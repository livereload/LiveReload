import Foundation

operator infix ||| {}

@infix public func ||| <T> (optional: T?, defaultValue: @auto_closure () -> T) -> T {
    if let unwrapped = optional {
        return unwrapped
    } else {
        return defaultValue()
    }
}
