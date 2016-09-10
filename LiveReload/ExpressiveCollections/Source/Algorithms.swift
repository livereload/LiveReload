import Foundation

public extension SequenceType {

    /// Find the first element passing the given test
    public func find(@noescape test: (Generator.Element) throws -> Bool) rethrows -> Generator.Element? {
        for item in self {
            if try test(item) {
                return item
            }
        }
        return nil
    }

    /// Like map, but the transform can return `nil` to skip elements.
    public func mapIf<U>(@noescape transform: (Generator.Element) throws -> U?) rethrows -> [U] {
        var result: [U] = []
        result.reserveCapacity(underestimateCount())
        for el in self {
            let optionalOutput = try transform(el)
            if let output = optionalOutput {
                result.append(output)
            }
        }
        return result
    }

    /// Find the first element for which the given function returns a non-nil result, and return that result.
    public func findMapped<U>(@noescape transform: (Generator.Element) throws -> U?) rethrows -> U? {
        for el in self {
            if let output = try transform(el) {
                return output
            }
        }
        return nil
    }

    /// Checks if all elements pass the given test.
    public func all(@noescape test: (Generator.Element) throws -> Bool) rethrows -> Bool {
        for item in self {
            if !(try test(item)) {
                return false
            }
        }
        return true
    }

    // looking for any()? see contains() in stdlib

    /// Returns a dictionary with elements keyed by the value of the given function.
    public func indexBy<K>(@noescape keyFunc: (Generator.Element) throws -> K?) rethrows -> [K: Generator.Element] {
        var result: [K: Generator.Element] = [:]
        for item in self {
            if let key = try keyFunc(item) {
                result[key] = item
            }
        }
        return result
    }

}

public extension SequenceType where Generator.Element: CollectionType {

    /// Turns an array of arrays into a flat array.
    public func flatten() -> [Generator.Element.Generator.Element] {
        var items: [Generator.Element.Generator.Element] = []
        for subsequence in self {
            items.appendContentsOf(subsequence)
        }
        return items
    }

    /// Turns an array of arrays into a flat array, interposing a separator element returned by the given function between each non-empty group.
    public func flattenWithSeparator(@noescape separator: () throws -> Generator.Element.Generator.Element) rethrows -> [Generator.Element.Generator.Element] {
        var result: [Generator.Element.Generator.Element] = []
        var separatorRequired = false

        for group in self {
            if group.isEmpty {
                continue;
            }
            if separatorRequired {
                result.append(try separator())
            }
            result.appendContentsOf(group)
            separatorRequired = true
        }

        return result
    }

    /// Turns an array of arrays into a flat array, interposing a given separator element between each non-empty group.
    public func flattenWithSeparator(separator: Generator.Element.Generator.Element) -> [Generator.Element.Generator.Element] {
        var result: [Generator.Element.Generator.Element] = []
        var separatorRequired = false

        for group in self {
            if group.isEmpty {
                continue;
            }
            if separatorRequired {
                result.append(separator)
            }
            result.appendContentsOf(group)
            separatorRequired = true
        }
        
        return result
    }

}

public extension RangeReplaceableCollectionType where Generator.Element: Equatable {

    /// Removes the given element from the collection, if it exists. If multiple elements are found, only the first one is removed.
    public mutating func removeElement(element: Generator.Element) {
        if let index = self.indexOf(element) {
            self.removeAtIndex(index)
        }
    }

    /// Removes the given elements from the collection. Only the first occurrence of each element is removed.
    public mutating func removeElements<S: SequenceType where S.Generator.Element == Generator.Element>(elements: S) {
        for item in elements {
            removeElement(item)
        }
    }

    /// If `!self.isEmpty`, remove the last element and return it, otherwise
    /// return `nil`.
    public mutating func popFirst() -> Generator.Element? {
        if isEmpty {
            return nil
        } else {
            return removeFirst()
        }
    }

}

public extension RangeReplaceableCollectionType where Index : BidirectionalIndexType {

    /// Removes the elements passing the given test from the collection.
    public mutating func removeElements(@noescape predicate: (Generator.Element) throws -> Bool) rethrows {
        let start = startIndex
        var cur = endIndex
        while cur != start {
            if try predicate(self[cur]) {
                removeAtIndex(cur)
            }
            --cur
        }
    }

}
