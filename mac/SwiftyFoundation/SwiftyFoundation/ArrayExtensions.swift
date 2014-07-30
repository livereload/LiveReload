import Foundation

// these extensions won't link currently, see https://devforums.apple.com/message/983747
// "It looks like the compiler gets the mangled symbol names of methods in generic extensions
// wrong when they live in a different framework"
//
// intentionally marked as internal for now. you'll need to copy these into your framework.

extension Array {

    func find(test: (Element) -> Bool) -> Element? {
        for item in self {
            if test(item) {
                return item
            }
        }
        return nil
    }

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

    func findMapped<U>(transform: (Element) -> U?) -> U? {
        for el in self {
            if let output = transform(el) {
                return output
            }
        }
        return nil
    }

    func all(test: (Element) -> Bool) -> Bool {
        for item in self {
            if !test(item) {
                return false
            }
        }
        return true
    }

    func contains(test: (Element) -> Bool) -> Bool {
        for item in self {
            if test(item) {
                return true
            }
        }
        return false
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

}
