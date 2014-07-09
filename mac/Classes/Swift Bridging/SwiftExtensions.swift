
import Foundation

func NV<T>(value: T?, defaultValue: T) -> T {
    if let v = value {
        return v
    } else {
        return defaultValue
    }
}

func NVCast<T>(value: AnyObject?, defaultValue: T) -> T {
    if let val: AnyObject = value {
        if let v = val as? T {
            return v
        } else {
            return defaultValue
        }
    } else {
        return defaultValue
    }
}

func safeCast<T>(value: AnyObject?, example: T) -> T? {
    if let v: AnyObject = value {
        return v as? T
    } else {
        return nil
    }
}

func stringValue(optionalValue: AnyObject?) -> String? {
    if let value: AnyObject = optionalValue {
        if let v = value as? String {
            return v
        } else {
            return "\(value)"
        }
    } else {
        return nil
    }
}

func boolValue(optionalValue: AnyObject?) -> Bool? {
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

func boolValue(value: AnyObject?, #defaultValue: Bool) -> Bool {
    return NV(boolValue(value), defaultValue)
}

func EmptyToNil(value: String?) -> String? {
    if value {
        if (value!.isEmpty) {
            return nil
        } else {
            return value
        }
    }
    return nil
}

func EmptyToNilCast(value: AnyObject?) -> String? {
    if let val: AnyObject = value {
        if let v = val as? String {
            return EmptyToNil(v)
        }
    }
    return nil
}

extension Optional {

    func omap<U>(f: (T) -> U?) -> U? {
        if let v = self {
            return f(v)
        } else {
            return nil
        }
    }

}

extension NSError {

    convenience init(_ domain: String, _ code: Int, _ description: String) {
        self.init(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }

}

extension String {

    var argumentsArrayUsingBourneQuotingStyle: [String] {
        let s = self as NSString
        return s.argumentsArrayUsingBourneQuotingStyle() as [String]
    }

}

extension Array {

    var quotedArgumentStringUsingBourneQuotingStyle: String {
        return (self as NSArray).quotedArgumentStringUsingBourneQuotingStyle()
    }

}

extension Dictionary {

//    init(dictionary: NSDictionary) {
//        self.init(minimumCapacity: dictionary.count)
//        updateValues(fromDictionary: dictionary)
//    }
//
//    mutating func updateValues(fromDictionary dictionary: NSDictionary) {
//        NSLog("Dictionary.updateValues %@", dictionary)
//        for (key: AnyObject, value: AnyObject) in dictionary {
//            NSLog("key = %@", key as NSObject)
//            let k = key as KeyType
//            NSLog("value = %@", value as NSObject)
//            let v = value as ValueType
//            self[key as KeyType] = ValueType?(value as ValueType)
//        }
//    }

}

func swiftify(#dictionary: NSDictionary) -> Dictionary<String, AnyObject> {
    var result = Dictionary<String, AnyObject>(minimumCapacity: dictionary.count)
    swiftify(dictionary: dictionary, into: &result)
    return result
}

func swiftify(#dictionary: NSDictionary, inout into result: Dictionary<String, AnyObject>) {
    for (key: AnyObject, value: AnyObject) in dictionary {
        let k = key as String
        result[k] = value
    }
}

struct IndexedArray<K: Hashable, V> {

    typealias IndexFunc = (V) -> K

    let indexFunc: IndexFunc

    var dictionary: Dictionary<K, V> = [:]
    var list: [V] = []

    init(indexFunc: IndexFunc) {
        self.indexFunc = indexFunc
    }

    subscript(key: K) -> V? {
        return dictionary[key];
    }

    mutating func append(value: V, overwrite: Bool = false) -> Bool {
        let key = indexFunc(value)
        if !overwrite {
            if let oldValue = self[key] {
                return false
            }
        }
        list.append(value)
        dictionary[key] = value
        return true
    }

    mutating func extend(values: [V], overwrite: Bool = false) {
        for value in values {
            append(value, overwrite: overwrite)
        }
    }

    mutating func removeAll() {
        dictionary = [:]
        list = []
    }

    func contains(value: V) -> Bool {
        let key = indexFunc(value)
        return self[key] ? true : false
    }

}
