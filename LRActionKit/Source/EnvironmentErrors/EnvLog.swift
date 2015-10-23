import Foundation
import ExpressiveFoundation

public class EnvLog: EmitterType {
    public var _listeners = EventListenerStorage()

    public struct DidChange: EventType {
    }
    
    public let origin: String

    public private(set) var errors: [String] = []
    public private(set) var warnings: [String] = []

    private var shallowErrors: [String] = []
    private var shallowWarnings: [String] = []
    private var parents: [WeakEnvLogRef] = []

    public var hasErrors: Bool {
        return !errors.isEmpty
    }

    private var children: [EnvLog] = [] {
        didSet {
            let newValue = children

            for child in oldValue {
                if nil == newValue.find({ $0 === child }) {
                    child.removeParent(self)
                }
            }
            for child in newValue {
                if nil == oldValue.find({ $0 === child }) {
                    child.addParent(self)
                }
            }
        }
    }

    public var annotatedErrors: [String] {
        return errors.map { annotate($0) }
    }

    public var annotatedWarnings: [String] {
        return warnings.map { annotate($0) }
    }

    public init(origin: String) {
        self.origin = origin
    }

    public func beginUpdating() -> EnvLogBuilder {
        return EnvLogBuilder(log: self)
    }

    private func update(fromBuilder builder: EnvLogBuilder) {
        shallowErrors = builder.errors
        shallowWarnings = builder.warnings
        children = builder.children

        didChange()
    }

    private func didChange() {
        errors = shallowErrors + children.flatMap { $0.annotatedErrors }
        warnings = shallowWarnings + children.flatMap { $0.annotatedWarnings }

        emit(DidChange())

        for parentRef in parents {
            if let parent = parentRef.value {
                parent.didChange()
            }
        }
    }

    private func annotate(message: String) -> String {
        if origin.isEmpty {
            return message
        } else {
            return "\(origin): \(message)"
        }
    }

    private func addParent(parent: EnvLog) {
        parents.append(WeakEnvLogRef(value: parent))
    }

    private func removeParent(parent: EnvLog) {
        if let idx = parents.indexOf({ $0.value === parent }) {
            parents.removeAtIndex(idx)
        }
    }

}

public class EnvLogBuilder {

    private let log: EnvLog

    private var errors: [String] = []
    private var warnings: [String] = []
    private var children: [EnvLog] = []

    private init(log: EnvLog) {
        self.log = log
    }

    deinit {
        commit()
    }

    public func addChild(log: EnvLog) {
        children.append(log)
    }

    public func addError(message: String, _ details: [String] = []) {
        errors.append(message)
    }

    public func addError(error: ErrorType) {
        errors.append("\(error)")
    }

    public func addError(message: String, _ error: ErrorType) {
        errors.append("\(message): \(error)")
    }

    public func addWarning(message: String, _ details: [String] = []) {
        warnings.append(message)
    }

    public func commit() {
        log.update(fromBuilder: self)
    }

}

private struct WeakEnvLogRef {
    weak var value: EnvLog?
    init (value: EnvLog) {
        self.value = value
    }
}
