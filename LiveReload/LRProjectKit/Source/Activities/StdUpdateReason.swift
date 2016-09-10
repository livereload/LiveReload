import Foundation

public enum StdUpdateReason: RequestType {

    case Initial
    case Periodic
    case ExternalChange
    case UserInitiated(site: OpSite)

    public func merge(other: StdUpdateReason, isRunning: Bool) -> StdUpdateReason? {
        switch (self, other) {
        case (.UserInitiated(site: let s1), .UserInitiated(site: let s2)):
            if s1.isRunning {
                s2.started()
            }
            return other

        case (.UserInitiated(_), _):
            return self
        case (_, .UserInitiated(_)):
            return other

        case (.ExternalChange, _):
            return self
        case (_, .ExternalChange):
            return other

        case (.Periodic, _):
            return self
        case (_, .Periodic):
            return other

        default:
            return self
        }
    }

}

public func == (a: StdUpdateReason, b: StdUpdateReason) -> Bool {
    switch (a, b) {
    case (.UserInitiated(site: let s1), .UserInitiated(site: let s2)):
        return s1 === s2
    case (.ExternalChange, .ExternalChange):
        return true
    case (.Periodic, .Periodic):
        return true
    case (.Initial, .Initial):
        return true
    default:
        return false
    }
}
