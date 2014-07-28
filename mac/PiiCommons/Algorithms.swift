import LRActionKit
import Swift

extension Array {

    func mapIf<U>(transform: (Element) -> U?) -> [U] {
        var result: [U] = []
        result.reserveCapacity(count)
        for el in self {
            let optionalOutput = transform(el)
            if let output = optionalOutput {
                result.append(output)
            }
        }
        return result
    }

    func findMapIf<U>(transform: (Element) -> U?) -> U? {
        for el in self {
            if let output = transform(el) {
                return output
            }
        }
        return nil
    }

    func all(test: (Element) -> Bool) -> Bool {
        for item in self {
            if test(item) {
                return true
            }
        }
        return false
    }

    func any(test: (Element) -> Bool) -> Bool {
        for item in self {
            if !test(item) {
                return false
            }
        }
        return true
    }

    var firstOrNil: Element? {
        if count > 0 {
            return self[0]
        } else {
            return nil
        }
    }

    var lastOrNil: Element? {
        let c = count
        if c > 0 {
            return self[c-1]
        } else {
            return nil
        }
    }

    mutating func removeFirstOrNil() -> Element? {
        if count > 0 {
            return self.removeAtIndex(0)
        } else {
            return nil
        }
    }

    mutating func removeLastOrNil() -> Element? {
        if count > 0 {
            return self.removeLast()
        } else {
            return nil
        }
    }

//    func find(el: Element) -> Int? {
//        for index in 0 .. count {
//            if self[index] === el {
//                return index
//            }
//        }
//        return nil
//    }
//
//    func removeValue(el: Element) {
//        if let index = find(array, el) {
//            array.removeAtIndex(index)
//        }
//    }
//
//    func removeIntersection<T: Equatable>(inout array: T[], sequence: T[]) {
//        for item in sequence {
//            remove(&array, item)
//        }
//    }

}

func flatten<T where T: Sequence, T.GeneratorType.Element: Sequence>(sequence: T) -> [T.GeneratorType.Element.GeneratorType.Element] {
    var items: [T.GeneratorType.Element.GeneratorType.Element] = []
    for subsequence in sequence {
        items.extend(subsequence)
    }
    return items
}

func findIf<S: Sequence>(sequence: S, test: (S.GeneratorType.Element) -> Bool) -> S.GeneratorType.Element? {
    for item in sequence {
        if test(item) {
            return item
        }
    }
    return nil
}

public func find<S : Sequence where S.GeneratorType.Element : Equatable>(domain: S, value: S.GeneratorType.Element) -> Bool {
    return find(domain, value) != nil
}

func all<S: Sequence>(sequence: S, test: (S.GeneratorType.Element) -> Bool) -> Bool {
    for item in sequence {
        if test(item) {
            return true
        }
    }
    return false
}

func any<S: Sequence>(sequence: S, test: (S.GeneratorType.Element) -> Bool) -> Bool {
    for item in sequence {
        if !test(item) {
            return false
        }
    }
    return true
}

func removeValue<T: Equatable>(inout array: [T], el: T) {
    if let index = find(array, el) {
        array.removeAtIndex(index)
    }
}

func removeIntersection<T: Equatable>(inout array: [T], sequence: [T]) {
    for item in sequence {
        removeValue(&array, item)
    }
}

//func removeIntersection<S: Sequence where S.GeneratorType.Element: Equatable>(inout array: S.GeneratorType.Element[], sequence: S) {
//    for item in sequence {
//        remove(&array, item)
//    }
//}
