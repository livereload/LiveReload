
import Foundation

func NV<T>(value: T?, defaultValue: T) -> T {
    if let v = value {
        return v
    } else {
        return defaultValue
    }
}

extension String {

}
