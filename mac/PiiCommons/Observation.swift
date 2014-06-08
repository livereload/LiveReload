import Foundation

//protocol Observer {
//
//    mutating func unobserve()
//
//}
//
//class NotificationObserver: Observer {
//
//    var value: AnyObject?
//
//    init(_ name: String, object: AnyObject? = nil, _ block: (NSNotification) -> Void) {
//        self.value = NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { block($0) })
//    }
//
//    convenience init(_ name: String, object: AnyObject? = nil, _ block: () -> Void) {
//        self.init(name, object: object, { (n: NSNotification) in block() })
//    }
//
//    deinit {
//        unobserve()
//    }
//
//    func unobserve() {
//        if let v: AnyObject = value {
//            NSNotificationCenter.defaultCenter().removeObserver(v)
//            value = nil
//        }
//    }
//
//}
//
//class WeakNotificationObserver<T: AnyObject>: NotificationObserver {
//
//    init(_ name: String, object: AnyObject? = nil, host: T, _ block: (T, NSNotification) -> Void) {
//        weak var ho: T? = host
//        super.init(name, object: object, { (notification: NSNotification) in
//            if let h = ho {
//                block(h, notification)
//            }
//            })
//    }
//
//    convenience init(_ name: String, object: AnyObject? = nil, host: T, _ block: (T) -> Void) {
//        self.init(name, object: object, host: host, { (h, n) in block(h) })
//    }
//
//}
//
//func observeNotification(name: String, object: AnyObject? = nil, block: (NSNotification) -> Void) -> Observer {
//    return NotificationObserver(name, object: object, block)
//}
//
//func observeNotification(name: String, object: AnyObject? = nil, block: () -> Void) -> Observer {
//    return NotificationObserver(name, object: object, block)
//}
//
//func observeNotification<T: AnyObject>(name: String, object: AnyObject? = nil, #host: T, block: (T, NSNotification) -> Void) -> Observer {
//    return WeakNotificationObserver<T>(name, object: object, host: host, block)
//}
//
//func observeNotification<T: AnyObject>(name: String, object: AnyObject? = nil, #host: T, invokeImmediately: Bool = false, block: (T) -> Void) -> Observer {
//    let observer = WeakNotificationObserver<T>(name, object: object, host: host, block)
//    if (invokeImmediately) {
//        block(host)
//    }
//    return observer
//}
//
//func observeNotification<T: AnyObject>(name: String, object: AnyObject? = nil, inout into observers: Observer[], #host: T, block: (T, NSNotification) -> Void) {
//    observers.append(WeakNotificationObserver<T>(name, object: object, host: host, block))
//}
//
//func observeNotification<T: AnyObject>(name: String, object: AnyObject? = nil, inout into observers: Observer[], #host: T, invokeImmediately: Bool = false, block: (T) -> Void) {
//    observers.append(WeakNotificationObserver<T>(name, object: object, host: host, block))
//    if (invokeImmediately) {
//        block(host)
//    }
//}

extension NSObject {

    func observeNotification(name: String, object: AnyObject?, selector: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: object)
    }

    func observeNotification(name: String, selector: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: nil)
    }

    func stopObservingNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func postNotification(name: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: self)
    }

}
