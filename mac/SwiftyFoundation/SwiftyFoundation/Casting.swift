import Foundation

public func BoolValue(optionalValue: AnyObject?) -> Bool? {
    if let value: AnyObject = optionalValue {
        if let v = value as? Bool {
            return v
        } else if let v = value as? Int {
            return v != 0
        } else if let v = value as? String {
            let u = v.uppercaseString
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
            if let num = v.toInt() {
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
            if scanner.scanDouble(&num) && scanner.atEnd {
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

//// useless right now, latest betas allow doing this as a simple cast
//public func DictionaryValue<T>(optionalValue: AnyObject?) -> [String: AnyObject]? {
//    if let value: AnyObject = optionalValue {
//        if let dictionary = value as? NSDictionary {
//            return dictionary as? [String: AnyObject]
//        } else {
//            return nil
//        }
//    } else {
//        return nil
//    }
//}


public func NonEmptyString(optionalValue: String?, trimWhitespace: Bool = true) -> String? {
    if let value = optionalValue {
        let trimmedValue: String = (trimWhitespace ? value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) : value);
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
