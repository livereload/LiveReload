import Foundation

private func ReducePrecision(value: Int) -> (Int, Int) {
    if value < 0 {
        let (a, b) = ReducePrecision(-value)
        return (-b, -a)
    } else if value == 0 {
        return (0, 0)
    } else if value == 1 {
        return (1, 1)
    } else if value <= 9 {
        return (2, 9)
    } else if value <= 29 {
        return (10, 29)
    } else if value <= 99 {
        return (30, 99)
    } else {
        let l = log10(Double(value))
        let k = floor(l)
        let a = Int(pow(10, k))
        let b = Int(pow(10, k+1)) - 1
        return (a, b)
    }
}

public struct ReducedPrecisionRange {
    let lower: Int
    let upper: Int

    public init(lower l: Int, upper u: Int) {
        lower = l
        upper = u
    }

    public init(value: Int) {
        let (l, u) = ReducePrecision(value)
        self.init(lower: l, upper: u)
    }
    
    public var description: String {
        if lower == upper {
            return "\(lower)"
        } else if lower < 0 || upper < 0 {
            return "\(lower)..\(upper)"
        } else {
            return "\(lower)-\(upper)"
        }
    }
}

@objc public class ATReducedPrecisionRange: NSObject {
    public class func reducedPrecisionRangeStringForValue(value: Int) -> String {
        return ReducedPrecisionRange(value: value).description
    }
}
