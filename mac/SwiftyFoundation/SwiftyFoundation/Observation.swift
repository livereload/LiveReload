import Foundation
import ObjectiveC

public struct Observation {
    private var observations: [ObservationProxy] = []

    public init() {
    }

    public mutating func on(name: String, object: AnyObject? = nil, _ block: (NSNotification) -> Void) {
        observations.append(NotificationObservationProxy(name: name, object: object, block: block))
    }

    public mutating func on <T: AnyObject> (name: String, object: AnyObject? = nil, _ observer: T, _ block: (T) -> (NSNotification) -> Void) {
        weak var weakObserver: T? = observer
        on(name, object: object) { notification in
            if let observer = weakObserver {
                block(observer)(notification)
            }
        }
    }

    public mutating func on <T: AnyObject> (name: String, object: AnyObject? = nil, _ observer: T, _ block: (T) -> () -> Void) {
        weak var weakObserver: T? = observer
        on(name, object: object) { notification in
            if let observer = weakObserver {
                block(observer)()
            }
        }
    }

    public mutating func unobserve() {
        observations = []
    }
}

private class ObservationProxy : NSObject {
}

private class NotificationObservationProxy : ObservationProxy {
    let name: String  // mostly for debugging purposes
    let block: (NSNotification) -> Void

    init(name: String, object: AnyObject? = nil, block: (NSNotification) -> Void) {
        self.name = name
        self.block = block
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "trigger:", name: name, object: object)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @objc func trigger(notification: NSNotification) {
        block(notification)
    }
}

extension NSObject {

    public func postNotification(name: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: self)
    }

}
