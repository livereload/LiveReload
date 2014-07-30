
// MARK: Any sequences

public func findIf<S: Sequence>(sequence: S, test: (S.GeneratorType.Element) -> Bool) -> S.GeneratorType.Element? {
    for item in sequence {
        if test(item) {
            return item
        }
    }
    return nil
}

public func findMapped<S: Sequence, U>(sequence: S, transform: (S.GeneratorType.Element) -> U?) -> U? {
    for item in sequence {
        if let value = transform(item) {
            return value
        }
    }
    return nil
}

public func mapIf<S: Sequence, U>(sequence: S, transform: (S.GeneratorType.Element) -> U?) -> [U] {
    var result: [U] = []
    for item in sequence {
        if let value = transform(item) {
            result.append(value)
        }
    }
    return result
}

public func all<S: Sequence>(sequence: S, test: (S.GeneratorType.Element) -> Bool) -> Bool {
    for item in sequence {
        if !test(item) {
            return false
        }
    }
    return true
}

// looking for any()? see contains() in stdlib

public func flatten<T where T: Sequence, T.GeneratorType.Element: Sequence>(sequence: T) -> [T.GeneratorType.Element.GeneratorType.Element] {
    var items: [T.GeneratorType.Element.GeneratorType.Element] = []
    for subsequence in sequence {
        items.extend(subsequence)
    }
    return items
}


// MARK: Arrays and random access collections

public func removeElement<T: Equatable>(inout array: [T], element: T) {
    if let index = find(array, element) {
        array.removeAtIndex(index)
    }
}

public func removeElements<T: Equatable>(inout array: [T], elements: [T]) {
    for element in elements {
        removeElement(&array, element)
    }
}

public func removeElements<S: Sequence where S.GeneratorType.Element: Equatable>(inout array: [S.GeneratorType.Element], elements: S) {
    for item in elements {
        removeElement(&array, item)
    }
}

public func removeElements<T>(inout array: [T], predicate: (T) -> Bool) {
    for var i = array.count - 1; i >= 0; --i {
        if predicate(array[i]) {
            array.removeAtIndex(i)
        }
    }
}
