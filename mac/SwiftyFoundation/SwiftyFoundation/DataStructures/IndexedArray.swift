import Foundation

public struct IndexedArray<K: Hashable, V> {

    public typealias IndexFunc = (V) -> K

    private let indexFunc: IndexFunc

    public private(set) var dictionary: Dictionary<K, V> = [:]
    public private(set) var list: [V] = []

    public init(indexFunc: IndexFunc) {
        self.indexFunc = indexFunc
    }

    public subscript(key: K) -> V? {
        return dictionary[key];
    }

    mutating public func append(value: V, overwrite: Bool = false) -> Bool {
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

    mutating public func extend(values: [V], overwrite: Bool = false) {
        for value in values {
            append(value, overwrite: overwrite)
        }
    }

    mutating public func removeAll() {
        dictionary = [:]
        list = []
    }

    public func contains(value: V) -> Bool {
        let key = indexFunc(value)
        return self[key] != nil
    }
    
}
