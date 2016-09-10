//
//  ExpressiveCasting
//
//  Copyright (c) 2014-2015 Andrey Tarantsov <andrey@tarantsov.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
import Foundation

// use fuzzy casting operators for reading untrusted data like NSUserDefaults or JSON.
// please abstain from abuse.

// "fuzzy cast",  aka  "make it so"
postfix operator ~~~ {}


postfix public func ~~~ (optional: AnyObject?) -> Bool? {
    return BoolValue(optional)
}

postfix public func ~~~ (optional: AnyObject?) -> Int? {
    return IntValue(optional)
}

postfix public func ~~~ (optional: AnyObject?) -> Double? {
    return DoubleValue(optional)
}

postfix public func ~~~ (optional: AnyObject?) -> String? {
    return NonEmptyStringValue(optional)
}

postfix public func ~~~ (optional: AnyObject?) -> [Int]? {
    return ArrayValue(optional) { IntValue($0) }
}

postfix public func ~~~ (optional: AnyObject?) -> [String]? {
    return ArrayValue(optional) { StringValue($0) }
}

postfix public func ~~~ (optional: AnyObject?) -> JSONObject? {
    return JSONObjectValue(optional)
}

postfix public func ~~~ (optional: AnyObject?) -> [JSONObject]? {
    return JSONObjectsArrayValue(optional)
}

postfix public func ~~~ (optional: AnyObject?) -> NSURL? {
    return URLValue(optional)
}

postfix public func ~~~ <T: JSONObjectConvertible> (optional: AnyObject?) -> T? {
    return JSONConvertibleObjectValue(optional)
}

postfix public func ~~~ <T: JSONObjectConvertible> (optional: AnyObject?) -> [T]? {
    return JSONConvertibleObjectsArrayValue(optional)
}
