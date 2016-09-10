# ExpressiveCollections.swift

Swift nanoframework for writing concise and expressive code involving standard Swift collections.


## Interface

All functions that accept a closure support Swift 2 error-throwing closures.

### Collection Algorithms

    extension SequenceType {

        /// Find the first element passing the given test
        func find(test: (Element) throws -> Bool) rethrows -> Element?

        /// Like map, but the transform can return `nil` to skip elements.
        func mapIf<U>(transform: (Element) throws -> U?) rethrows -> [U]

        /// Find the first element for which the given function returns a non-nil result, and return that result.
        func findMapped<U>(transform: (Element) throws -> U?) rethrows -> U?

        /// Checks if all elements pass the given test.
        func all(test: (Element) throws -> Bool) rethrows -> Bool

        // looking for any()? see contains() in stdlib

        /// Returns a dictionary with elements keyed by the value of the given function.
        func indexBy<K>(keyFunc: (Element) throws -> K?) rethrows -> [K : Element]
    }

    extension SequenceType where Element : CollectionType {

        /// Turns an array of arrays into a flat array.
        func flatten() -> [Element.Element]

        /// Turns an array of arrays into a flat array, interposing a separator element
        /// returned by the given function between each non-empty group.
        func flattenWithSeparator(separator: () throws -> Element.Element) rethrows -> [Element.Element]

        /// Turns an array of arrays into a flat array, interposing a given separator element between each non-empty group.
        func flattenWithSeparator(separator: Element.Element) -> [Element.Element]
    }

    extension RangeReplaceableCollectionType where Element : Equatable {

        /// Removes the given element from the collection, if it exists.
        /// If multiple elements are found, only the first one is removed.
        mutating func removeElement(element: Element)

        /// Removes the given elements from the collection. Only the first occurrence of each element is removed.
        mutating func removeElements<S : SequenceType where S.Element == Element>(elements: S)
    }

    extension RangeReplaceableCollectionType where Index : BidirectionalIndexType {

        /// Removes the elements passing the given test from the collection.
        mutating func removeElements(predicate: (Element) throws -> Bool) rethrows

    }


### Collection Operators

Ruby-style array append operator:

    var array = [1, 2, 3]
    array <<< 42

`+=` for dictionaries:

    var dict = ["Foo": 1]
    dict += ["Bar": 2]


### IndexedArray

    /// An array that supports `O(1)` lookup of elements
    /// by return values by the given function.
    struct IndexedArray <K: Hashable, V> {

        typealias IndexFunc = (V) -> K

        var dictionary: Dictionary<K, V>  { get }

        var list: [V]  { get }

        init(indexFunc: IndexFunc)

        subscript (key: K) -> V? { get }

        mutating func append(value: V, overwrite: Bool = default) -> Bool

        mutating func extend(values: [V], overwrite: Bool = default)

        mutating func removeAll()

        func contains(value: V) -> Bool
    }
