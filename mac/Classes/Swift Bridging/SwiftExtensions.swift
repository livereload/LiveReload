
import Foundation

func NV<T>(value: T?, defaultValue: T) -> T {
    if let v = value {
        return v
    } else {
        return defaultValue
    }
}

func EmptyToNil(value: String?) -> String? {
    if value {
        if (value!.isEmpty) {
            return nil
        }
    }
    return value
}

extension String {

}

struct IndexedArray<K: Hashable, V> {

    typealias IndexFunc = (V) -> K

    let indexFunc: IndexFunc

    var dictionary: Dictionary<K, V> = [:]
    var list: V[] = []

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

    mutating func removeAll() {
        dictionary = [:]
        list = []
    }

}

func flatten<T where T: Sequence, T.GeneratorType.Element: Sequence>(sequence: T) -> T.GeneratorType.Element.GeneratorType.Element[] {
    var items: T.GeneratorType.Element.GeneratorType.Element[] = []
    for subsequence in sequence {
        items.extend(subsequence)
    }
    return items
}

func findWhere<S: Sequence>(sequence: S, test: (S.GeneratorType.Element) -> Bool) -> S.GeneratorType.Element? {
    for item in sequence {
        if test(item) {
            return item
        }
    }
    return nil
}

func contains<C: Swift.Collection where C.GeneratorType.Element: Equatable>(collection: C, value: C.GeneratorType.Element) -> Bool {
    return find(collection, value) != nil
}

