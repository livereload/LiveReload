import Foundation

// use fuzzy casting operators for reading untrusted data like NSUserDefaults or JSON.
// please abstain from abuse.

// "fuzzy cast",  aka  "make it so"
postfix operator ~~~ {}

// "fuzzy object OR",  aka  "make it so, or else"
infix operator ~|||~ {}


postfix public func ~~~ (optional: AnyObject?) -> Bool? {
    return BoolValue(optional)
}

public func ~|||~ (optional: AnyObject?, defaultValue: Bool) -> Bool {
    return optional~~~ ?? defaultValue
}


postfix public func ~~~ (optional: AnyObject?) -> Int? {
    return IntValue(optional)
}

public func ~|||~ (optional: AnyObject?, defaultValue: Int) -> Int {
    return optional~~~ ?? defaultValue
}


postfix public func ~~~ (optional: AnyObject?) -> Double? {
    return DoubleValue(optional)
}

public func ~|||~ (optional: AnyObject?, defaultValue: Double) -> Double {
    return optional~~~ ?? defaultValue
}


postfix public func ~~~ (optional: AnyObject?) -> String? {
    return NonEmptyStringValue(optional)
}

public func ~|||~ (optional: AnyObject?, defaultValue: String) -> String {
    return optional~~~ ?? defaultValue
}


postfix public func ~~~ (optional: AnyObject?) -> [Int]? {
    return ArrayValue(optional, { IntValue($0) })
}

public func ~|||~ (optional: AnyObject?, defaultValue: [Int]) -> [Int] {
    return optional~~~ ?? defaultValue
}


postfix public func ~~~ (optional: AnyObject?) -> [String]? {
    return ArrayValue(optional, { StringValue($0) })
}

public func ~|||~ (optional: AnyObject?, defaultValue: [String]) -> [String] {
    return optional~~~ ?? defaultValue
}
