
import Foundation

// () -> Void
func weakify<T: AnyObject>(object: T, block: (T) -> Void) -> () -> Void {
    weak var weakObject = object
    return {
        if let strongObject = weakObject {
            block(strongObject)
        }
    }
}

// () -> R
func weakify<T: AnyObject, R>(object: T, block: (T) -> R?) -> () -> R? {
    weak var weakObject = object
    return {
        if let strongObject = weakObject {
            return block(strongObject)
        } else {
            return nil
        }
    }
}

// (A1) -> Void
func weakify<T: AnyObject, A1>(object: T, block: (T, A1) -> Void) -> (A1) -> Void {
    weak var weakObject = object
    return { (a1) in
        if let strongObject = weakObject {
            block(strongObject, a1)
        }
    }
}

// (A1) -> R
func weakify<T: AnyObject, A1, R>(object: T, block: (T, A1) -> R?) -> (A1) -> R? {
    weak var weakObject = object
    return { (a1) in
        if let strongObject = weakObject {
            return block(strongObject, a1)
        } else {
            return nil
        }
    }
}

// (A1, A2) -> Void
func weakify<T: AnyObject, A2, A1>(object: T, block: (T, A1, A2) -> Void) -> (A1, A2) -> Void {
    weak var weakObject = object
    return { (a1, a2) in
        if let strongObject = weakObject {
            block(strongObject, a1, a2)
        }
    }
}

// (A1, A2) -> R
func weakify<T: AnyObject, A1, A2, R>(object: T, block: (T, A1, A2) -> R?) -> (A1, A2) -> R? {
    weak var weakObject = object
    return { (a1, a2) in
        if let strongObject = weakObject {
            return block(strongObject, a1, a2)
        } else {
            return nil
        }
    }
}
