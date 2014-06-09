import Foundation

extension Array {

    func mapIf<U>(transform: (Element) -> U?) -> U[] {
        var result: U[] = []
        result.reserveCapacity(count)
        for el in self {
            let optionalOutput = transform(el)
            if let output = optionalOutput {
                result.append(output)
            }
        }
        return result
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

}

func flatten<T where T: Sequence, T.GeneratorType.Element: Sequence>(sequence: T) -> T.GeneratorType.Element.GeneratorType.Element[] {
    var items: T.GeneratorType.Element.GeneratorType.Element[] = []
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

func contains<C: Swift.Collection where C.GeneratorType.Element: Equatable>(collection: C, value: C.GeneratorType.Element) -> Bool {
    return find(collection, value) != nil
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
