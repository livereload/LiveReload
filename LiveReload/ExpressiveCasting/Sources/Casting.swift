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

public typealias JSONObject = [String: AnyObject]
public typealias JSONArray = [AnyObject]

public protocol JSONObjectConvertible {
    init(raw: JSONObject) throws
}


// MARK: Simple values

public func BoolValue(optionalValue: AnyObject?) -> Bool? {
    if let value: AnyObject = optionalValue {
        if let v = value as? Bool {
            return v
        } else if let v = value as? Int {
            return v != 0
        } else if let v = value as? String {
            #if swift(>=3.0)
            let u = v.uppercased()
            #else
            let u = v.uppercaseString
            #endif
            if (u == "YES" || u == "TRUE" || u == "ON" || u == "Y" || u == "1") {
                return true
            } else if (u == "NO" || u == "FALSE" || u == "OFF" || u == "N" || u == "0") {
                return false
            } else {
                return nil
            }
        } else {
            return nil
        }
    } else {
        return nil
    }
}

public func IntValue(optionalValue: AnyObject?) -> Int? {
    if let value: AnyObject = optionalValue {
        if let v = value as? Int {
            return v
        } else if let v = value as? String {
            if let num = Int(v) {
                return num
            } else {
                return nil
            }
        } else {
            return nil
        }
    } else {
        return nil
    }
}

public func DoubleValue(optionalValue: AnyObject?) -> Double? {
    if let value: AnyObject = optionalValue {
        if let v = value as? Double {
            return v
        } else if let v = value as? Int {
            return Double(v)
        } else if let v = value as? String {
            let scanner = NSScanner(string: v)
            var num: Double = 0.0
            #if swift(>=3.0)
            let isAtEnd = scanner.isAtEnd
            #else
            let isAtEnd = scanner.atEnd
            #endif
            if scanner.scanDouble(&num) && isAtEnd {
                return num
            } else {
                return nil
            }
        } else {
            return nil
        }
    } else {
        return nil
    }
}

public func StringValue(optionalValue: AnyObject?) -> String? {
    if let value: AnyObject = optionalValue {
        if let v = value as? String {
            return v
        } else if let v = value as? Int {
            return "\(v)"
        } else if let v = value as? Double {
            return "\(v)"
        } else {
            return nil
        }
    } else {
        return nil
    }
}

public func NonEmptyString(optionalValue: String?, trimWhitespace: Bool = true) -> String? {
    if let value = optionalValue {
        #if swift(>=3.0)
        let trimmedValue: String = (trimWhitespace ? value.trimmingCharacters(in: NSCharacterSet.whitespaceAndNewline()) : value);
        #else
        let trimmedValue: String = (trimWhitespace ? value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) : value);
        #endif
        if trimmedValue.isEmpty {
            return nil
        } else {
            return trimmedValue
        }
    } else {
        return nil
    }
}

public func NonEmptyStringValue(optionalValue: AnyObject?, trimWhitespace: Bool = true) -> String? {
    if let value = StringValue(optionalValue) {
        return NonEmptyString(value, trimWhitespace: trimWhitespace)
    } else {
        return nil
    }
}


// MARK: Foundation values


public func URLValue(optionalValue: AnyObject?) -> NSURL? {
    if let string = NonEmptyStringValue(optionalValue) {
        return NSURL(string: string)
    } else {
        return nil
    }
}


// MARK: Collection values

public func ArrayValue<T>(optionalValue: AnyObject?, itemMapper: (AnyObject) -> T?) -> [T]? {
    if let value: AnyObject = optionalValue {
        if let array = value as? [AnyObject] {
            var result: [T] = []
            for item in array {
                if let mapped = itemMapper(item) {
                    result.append(mapped)
                } else {
                    return nil
                }
            }
            return result
        } else {
            return nil
        }
    } else {
        return nil
    }
}

public func JSONObjectValue(optionalValue: AnyObject?) -> JSONObject? {
    return optionalValue as? [String: AnyObject]
}

public func JSONObjectsArrayValue(optionalValue: AnyObject?) -> [JSONObject]? {
    return ArrayValue(optionalValue) { JSONObjectValue($0) }
}


// MARK: JSONObjectConvertible

public func JSONConvertibleObjectValue <T: JSONObjectConvertible> (optional: AnyObject?) -> T? {
    if let raw: JSONObject = JSONObjectValue(optional) {
        return try? T(raw: raw)
    } else {
        return nil
    }
}

public func JSONConvertibleObjectsArrayValue <T: JSONObjectConvertible> (optional: AnyObject?) -> [T]? {
    if let raw: [JSONObject] = JSONObjectsArrayValue(optional) {
        var result: [T] = []
        #if swift(>=3.0)
        result.reserveCapacity(raw.underestimatedCount)
        #else
        result.reserveCapacity(raw.underestimateCount())
        #endif
        for el in raw {
            if let output: T = try? T(raw: el) {
                result.append(output)
            }
        }
        return result
    } else {
        return nil
    }
}

