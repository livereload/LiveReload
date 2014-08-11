
// MARK: Any sequences

public func findIf<S: SequenceType>(sequence: S, test: (S.Generator.Element) -> Bool) -> S.Generator.Element? {
    for item in sequence {
        if test(item) {
            return item
        }
    }
    return nil
}

public func findMapped<S: SequenceType, U>(sequence: S, transform: (S.Generator.Element) -> U?) -> U? {
    for item in sequence {
        if let value = transform(item) {
            return value
        }
    }
    return nil
}

public func mapIf<S: SequenceType, U>(sequence: S, transform: (S.Generator.Element) -> U?) -> [U] {
    var result: [U] = []
    for item in sequence {
        if let value = transform(item) {
            result.append(value)
        }
    }
    return result
}

public func all<S: SequenceType>(sequence: S, test: (S.Generator.Element) -> Bool) -> Bool {
    for item in sequence {
        if !test(item) {
            return false
        }
    }
    return true
}

// looking for any()? see contains() in stdlib

public func flatten<T where T: SequenceType, T.Generator.Element: SequenceType>(sequence: T) -> [T.Generator.Element.Generator.Element] {
    var items: [T.Generator.Element.Generator.Element] = []
    for subsequence in sequence {
        items.extend(subsequence)
    }
    return items
}


// MARK: Arrays and random access collections

public func firstOf<T>(items: [T]) -> T? {
    return items.isEmpty ? nil : items[0]
}

public func lastOf<T>(items: [T]) -> T? {
    return items.isEmpty ? nil : items[items.count - 1]
}

public func popFirst<T>(inout items: [T]) -> T? {
    if items.isEmpty {
        return nil
    } else {
        return items.removeAtIndex(0)
    }
}

public func popLast<T>(inout items: [T]) -> T? {
    if items.isEmpty {
        return nil
    } else {
        return items.removeLast()
    }
}

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

public func removeElements<S: SequenceType where S.Generator.Element: Equatable>(inout array: [S.Generator.Element], elements: S) {
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

public func flattenWithSeparator<T>(groups: [[T]], #separator: () -> T) -> [T] {
    var result: [T] = []
    var separatorRequired = false

    for group in groups {
        if group.isEmpty {
            continue;
        }
        if separatorRequired {
            result.append(separator())
        }
        result.extend(group)
        separatorRequired = true
    }

    return result
}

public func flattenWithSeparator<T>(groups: [[T]], #separator: T) -> [T] {
    var result: [T] = []
    var separatorRequired = false

    for group in groups {
        if group.isEmpty {
            continue;
        }
        if separatorRequired {
            result.append(separator)
        }
        result.extend(group)
        separatorRequired = true
    }

    return result
}
