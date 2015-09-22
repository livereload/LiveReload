import Foundation

public extension SequenceType {

    public func find(@noescape test: (Generator.Element) throws -> Bool) rethrows -> Generator.Element? {
        for item in self {
            if try test(item) {
                return item
            }
        }
        return nil
    }

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

    public func findMapped<U>(@noescape transform: (Generator.Element) throws -> U?) rethrows -> U? {
        for el in self {
            if let output = try transform(el) {
                return output
            }
        }
        return nil
    }

    public func all(@noescape test: (Generator.Element) throws -> Bool) rethrows -> Bool {
        for item in self {
            if !(try test(item)) {
                return false
            }
        }
        return true
    }

    // looking for any()? see contains() in stdlib

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

    public func flatten() -> [Generator.Element.Generator.Element] {
        var items: [Generator.Element.Generator.Element] = []
        for subsequence in self {
            items.appendContentsOf(subsequence)
        }
        return items
    }

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

    public mutating func removeElement(element: Generator.Element) {
        if let index = self.indexOf(element) {
            self.removeAtIndex(index)
        }
    }

    public mutating func removeElements<S: SequenceType where S.Generator.Element == Generator.Element>(elements: S) {
        for item in elements {
            removeElement(item)
        }
    }

}

public extension RangeReplaceableCollectionType where Index : BidirectionalIndexType {

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
