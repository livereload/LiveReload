import Foundation

public enum VersionError: ErrorType {
    case InvalidVersionNumber
    case InvalidExtraVersionNumber
    case InvalidPrereleaseComponent
    case InvalidRangeSpec
}
