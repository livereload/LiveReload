import Foundation

public protocol KeyValueStore: NSObjectProtocol {
    
    subscript (key: String) -> AnyObject? {
        get
        set
    }
    
}

public class UserDefaultsKeyValueStore: NSObject, KeyValueStore {
    
    private let prefix: String
    
    private let defaults: NSUserDefaults
    
    public class var standardDefaults: UserDefaultsKeyValueStore {
        struct Static {
            static let instance: UserDefaultsKeyValueStore = UserDefaultsKeyValueStore(prefix: "")
        }
        return Static.instance
    }

    public init(prefix: String) {
        self.prefix = prefix
        defaults = NSUserDefaults.standardUserDefaults()
        super.init()
    }
    
    public subscript (key: String) -> AnyObject? {
        get {
            return defaults.objectForKey(defaultsKeyForKey(key))
        }
        set {
            if newValue != nil {
                defaults.setObject(newValue, forKey: defaultsKeyForKey(key))
            } else {
                defaults.removeObjectForKey(defaultsKeyForKey(key))
            }
        }
    }
    
    private func defaultsKeyForKey(key: String) -> String {
        return prefix + key
    }
    
}

public class MemoryKeyValueStore: NSObject, KeyValueStore {
    
    public var values: [String: AnyObject] = [:]
    
    public override init() {
        super.init()
    }
    
    public subscript (key: String) -> AnyObject? {
        get {
            return values[key]
        }
        set {
            values[key] = newValue
        }
    }
    
}
