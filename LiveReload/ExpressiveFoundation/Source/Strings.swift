import Foundation

public extension String {

    public mutating func removePrefixInPlace(prefix: String) -> Bool {
        if prefix.isEmpty {
            return false
        }
        if hasPrefix(prefix) {
            guard let range = rangeOfString(prefix, options: []) else {
                fatalError()
            }
            self.removeRange(startIndex ..< range.startIndex)
            return true
        } else {
            return false
        }
    }

    public mutating func removeSuffixInPlace(suffix: String) -> Bool {
        if suffix.isEmpty {
            return false
        }
        if hasSuffix(suffix) {
            guard let range = rangeOfString(suffix, options: [.BackwardsSearch]) else {
                fatalError()
            }
            self.removeRange(range.startIndex ..< endIndex)
            return true
        } else {
            return false
        }
    }

    public func removePrefix(suffix: String) -> (String, Bool) {
        var copy = self
        let found = copy.removePrefixInPlace(suffix)
        return (copy, found)
    }

    public func removeSuffix(suffix: String) -> (String, Bool) {
        var copy = self
        let found = copy.removeSuffixInPlace(suffix)
        return (copy, found)
    }

    public func removePrefixOrNil(prefix: String) -> String? {
        var copy = self
        if copy.removePrefixInPlace(prefix) {
            return copy
        } else {
            return nil
        }
    }

    public mutating func replaceSuffixInPlace(oldSuffix: String, _ newSuffix: String) -> Bool {
        if removeSuffixInPlace(oldSuffix) {
            appendContentsOf(newSuffix)
            return true
        } else {
            return false
        }
    }

    public func replaceSuffix(oldSuffix: String, _ newSuffix: String) -> (String, Bool) {
        var copy = self
        let found = copy.replaceSuffixInPlace(oldSuffix, newSuffix)
        return (copy, found)
    }

}
