import Foundation

// use fuzzy casting operators for reading untrusted data like NSUserDefaults or JSON.
// please abstain from abuse.

// "fuzzy cast",  aka  "make it so"
operator postfix ~~~ {}

// "fuzzy object OR",  aka  "make it so, or else"
operator infix ~|||~ {}


@postfix public func ~~~ (optional: AnyObject?) -> Bool? {
    return BoolValue(optional)
}

@infix public func ~|||~ (optional: AnyObject?, defaultValue: Bool) -> Bool {
    return optional~~~ ||| defaultValue
}


@postfix public func ~~~ (optional: AnyObject?) -> Int? {
    return IntValue(optional)
}

@infix public func ~|||~ (optional: AnyObject?, defaultValue: Int) -> Int {
    return optional~~~ ||| defaultValue
}


@postfix public func ~~~ (optional: AnyObject?) -> Double? {
    return DoubleValue(optional)
}

@infix public func ~|||~ (optional: AnyObject?, defaultValue: Double) -> Double {
    return optional~~~ ||| defaultValue
}


@postfix public func ~~~ (optional: AnyObject?) -> String? {
    return NonEmptyStringValue(optional)
}

@infix public func ~|||~ (optional: AnyObject?, defaultValue: String) -> String {
    return optional~~~ ||| defaultValue
}


@postfix public func ~~~ (optional: AnyObject?) -> [Int]? {
    return ArrayValue(optional, { IntValue($0) })
}

@infix public func ~|||~ (optional: AnyObject?, defaultValue: [Int]) -> [Int] {
    return optional~~~ ||| defaultValue
}


@postfix public func ~~~ (optional: AnyObject?) -> [String]? {
    return ArrayValue(optional, { StringValue($0) })
}

@infix public func ~|||~ (optional: AnyObject?, defaultValue: [String]) -> [String] {
    return optional~~~ ||| defaultValue
}
