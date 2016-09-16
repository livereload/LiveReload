import Foundation

public enum ChangeReason {

    case Loading
    case Automatic
    case External
    case UserInitiated(site: ActionSite)

    public func merge(other: ChangeReason) -> ChangeReason {
        switch (self, other) {
        case (.UserInitiated(site: _), .UserInitiated(site: _)):
            return other
            
        case (.UserInitiated(_), _):
            return self
        case (_, .UserInitiated(_)):
            return other
            
        case (.External, _):
            return self
        case (_, .External):
            return other
            
        case (.Automatic, _):
            return self
        case (_, .Automatic):
            return other
            
        default:
            return self
        }
    }
    
}

public func == (a: ChangeReason, b: ChangeReason) -> Bool {
    switch (a, b) {
    case (.UserInitiated(site: let s1), .UserInitiated(site: let s2)):
        return s1 === s2
    case (.External, .External):
        return true
    case (.Automatic, .Automatic):
        return true
    case (.Loading, .Loading):
        return true
    default:
        return false
    }
}

public protocol ActionSite: class {
}

public class NullSite: ActionSite {
}
