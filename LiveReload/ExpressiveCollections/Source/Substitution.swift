import Foundation

public extension String {

    public func substituteValues(values: [String: String]) -> String {
        var result = self
        for (k, v) in values {
            result = result.stringByReplacingOccurrencesOfString(k, withString: v)
        }
        return result
    }

    public func substituteValues(values: [String: [String]]) -> [String] {
        for (k, v) in values {
            if self == k {
                return v
            }
        }

        var result = self
        for (k, v) in values {
            if v.count == 1 {
                result = result.stringByReplacingOccurrencesOfString(k, withString: v[0])
            }
        }
        return [result]
    }

}

public extension SequenceType where Generator.Element == String {

    public func substituteValues(values: [String: String]) -> [String] {
        return self.map { $0.substituteValues(values) }
    }

    public func substituteValues(values: [String: [String]]) -> [String] {
        return self.flatMap { $0.substituteValues(values) }
    }

}
