import Foundation
import ObjectiveC

public protocol ListenerType: class {
}

public struct Observation {
    private var observers: [ListenerType] = []

    public init() {}

    public mutating func add(observer: ListenerType) {
        observers.append(observer)
    }

    public mutating func unobserve() {
        observers = []
    }
}

public func += (inout observation: [ListenerType], observer: ListenerType) {
    observation.append(observer)
}

public func += (inout observation: Observation, observer: ListenerType) {
    observation.add(observer)
}
