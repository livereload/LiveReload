import Foundation


// MARK: - Wildcard observation

public extension Observation {
    public mutating func on(name: String, _ block: (NSNotification) -> Void) {
        add(NotificationObserver(name: name, object: nil, block: block))
    }

    public mutating func on <T: AnyObject> (name: String, _ observer: T, _ block: (T) -> (NSNotification) -> Void) {
        weak var weakObserver: T? = observer
        on(name) { notification in
            if let observer = weakObserver {
                block(observer)(notification)
            }
        }
    }

    public mutating func on <T: AnyObject> (name: String, _ observer: T, _ block: (T) -> () -> Void) {
        weak var weakObserver: T? = observer
        on(name) { notification in
            if let observer = weakObserver {
                block(observer)()
            }
        }
    }
}


// MARK: - Instance observation

public extension Observation {
    public mutating func on(name: String, from object: AnyObject, _ block: (NSNotification) -> Void) {
        add(NotificationObserver(name: name, object: object, block: block))
    }

    public mutating func on <T: AnyObject> (name: String, from object: AnyObject, _ observer: T, _ block: (T) -> (NSNotification) -> Void) {
        weak var weakObserver: T? = observer
        on(name, from: object) { notification in
            if let observer = weakObserver {
                block(observer)(notification)
            }
        }
    }

    public mutating func on <T: AnyObject> (name: String, from object: AnyObject, _ observer: T, _ block: (T) -> () -> Void) {
        weak var weakObserver: T? = observer
        on(name, from: object) { notification in
            if let observer = weakObserver {
                block(observer)()
            }
        }
    }
}


// MARK: -

private class NotificationObserver: NSObject, ListenerType {
    let name: String  // for debugging purposes
    let block: (NSNotification) -> Void

    init(name: String, object: AnyObject? = nil, block: (NSNotification) -> Void) {
        self.name = name
        self.block = block
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(trigger), name: name, object: object)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @objc func trigger(notification: NSNotification) {
        block(notification)
    }
}


public extension NSObject {

    public func postNotification(name: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: self)
    }
    
}
