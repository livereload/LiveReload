import Foundation

public class ChangeBus {

    public static let notification = "didChange"

    public static let instance = ChangeBus()

    public static func subscribe(handler: ChangeHandler) {
        instance.subscribe(handler)
    }

    public static func didChange() {
        instance.didChange()
    }


    private var isScheduled = false

    private var subscribers: [ChangeHandler] = []

    public func subscribe(handler: ChangeHandler) {
        subscribers.append(handler)
    }

    public func didChange() {
        if isScheduled {
            return
        }
        isScheduled = true
        dispatch_async(dispatch_get_main_queue()) {
            self.isScheduled = false

            for handler in self.subscribers {
                print("ChangeBus: notifying \(handler.dynamicType)")
                handler.handleChange()
            }

            NSNotificationCenter.defaultCenter().postNotificationName(ChangeBus.notification, object: nil)
            NSNotificationCenter.defaultCenter().postNotificationName("SomethingDidChange", object: nil)  // for compat with legacy LR2 code
        }
    }

}

public protocol ChangeHandler: class {

    func handleChange()

}

public protocol Change: class {

    func canApply() -> Bool
    
    func canUnapply() -> Bool
    
    func apply() -> Bool
    
    func unapply() -> Bool
    
}

public class BaseChange<T>: Change {
    
    private var applied = false

    public final func canApply() -> Bool {
        if let resolved = resolve() {
            return check(resolved) && checksApply(resolved)
        } else {
            return false
        }
    }
    
    public final func canUnapply() -> Bool {
        if let resolved = resolve() {
            return check(resolved) && checkUnapply(resolved)
        } else {
            return false
        }
    }

    public final func apply() -> Bool {
        guard !applied else {
            return true
        }

        if let resolved = resolve() {
            if check(resolved) && checksApply(resolved) {
                applied = true
                apply(resolved)
                return true
            }
        }
        return false
    }
    
    public final func unapply() -> Bool {
        guard applied else {
            return true
        }
        
        if let resolved = resolve() {
            if check(resolved) && checksApply(resolved) {
                applied = false
                apply(resolved)
                return true
            }
        }
        return false
    }
    
    public /*protected*/ func resolve() -> T? {
        return nil
    }
    
    public /*protected*/ func check(resolved: T) -> Bool {
        return true
    }
    
    public /*protected*/ func checksApply(resolved: T) -> Bool {
        return true
    }
    
    public /*protected*/ func checkUnapply(resolved: T) -> Bool {
        return true
    }
    
    public /*protected*/ func apply(resolved: T) {
    }
    
    public /*protected*/ func unapply(resolved: T) {
    }

}
