import Foundation

public class EnvLog {

    public let origin: String

    private var errors: [String] = []
    private var warnings: [String] = []

    public init(origin: String) {
        self.origin = origin
    }

    public func beginUpdating() -> EnvLogBuilder {
        return EnvLogBuilder(log: self)
    }

    private func update(fromBuilder builder: EnvLogBuilder) {
        errors = builder.errors
        warnings = builder.warnings
    }

}

public class EnvLogBuilder {

    private let log: EnvLog

    private var errors: [String] = []
    private var warnings: [String] = []

    private init(log: EnvLog) {
        self.log = log
    }

    deinit {
        commit()
    }

    public func addError(message: String) {
        errors.append(message)
    }

    public func addError(error: ErrorType) {
        errors.append("\(error)")
    }

    public func addError(message: String, error: ErrorType) {
        errors.append("\(message): \(error)")
    }

    public func addWarning(message: String) {
        warnings.append(message)
    }

    public func commit() {
        log.update(fromBuilder: self)
    }

}
