import Foundation

internal extension String {

    internal mutating func removeSuffixInPlace(suffix: String) -> Bool {
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

    internal func removeSuffix(suffix: String) -> (String, Bool) {
        var copy = self
        let found = copy.removeSuffixInPlace(suffix)
        return (copy, found)
    }

    internal mutating func replaceSuffixInPlace(oldSuffix: String, _ newSuffix: String) -> Bool {
        if removeSuffixInPlace(oldSuffix) {
            appendContentsOf(newSuffix)
            return true
        } else {
            return false
        }
    }

    internal func replaceSuffix(oldSuffix: String, _ newSuffix: String) -> (String, Bool) {
        var copy = self
        let found = copy.replaceSuffixInPlace(oldSuffix, newSuffix)
        return (copy, found)
    }

}
