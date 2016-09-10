//
//  ExpressiveEvents, part of ExpressiveSwift project
//
//  Copyright (c) 2014-2015 Andrey Tarantsov <andrey@tarantsov.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public protocol EmitterType: class {

    func emit(event: EventType)

    func subscribe(listener: EventListenerType)

    func unsubscribe(listener: EventListenerType)

}

public extension EmitterType {

    public func _emitAsNotification(event: EventType) {
        if let eventWN = event as? EventTypeWithNotification {
            NSNotificationCenter.defaultCenter().postNotificationName(eventWN.dynamicType.notificationName, object: self, userInfo: eventWN.notificationUserInfo)
        }
    }
    
}

/**
 A specific emitter implementation that contains a stored list of event listeners.

 To implement this protocol, declare a mutable `_listeners` property, initially set to `EventListenerStorage()`:

 ```
 class Foo: StdEmitterType {
 ...

 var _listeners = EventListenerStorage()
 }
 ```

 Please use StdEmitterType only for classes. For _protocols_, you should generally use EmitterType instead:

 ```
 protocol FooType: EmitterType {
 ...
 }
 class Foo: FooType, StdEmitterType {
 ...
 var _listeners = EventListenerStorage()
 }
 ```

 _An important contract detail that you don't need to understand unless you're planning to do funny things with events:_ Instances of StdEmitterType are always assumed to emit events with themselves as the type of the emitter. (As opposed to EmitterType, which may emit events with any other EmitterType.)

 */
public protocol StdEmitterType: EmitterType {

    /**
     This MUST be an instance of EventListenerStorage unique to this object;
     you are not allowed to return `someOtherObject._listeners` here.
     (Doing so would break the assumption that StdEmitterType objects always
     emit events with emitters that are instances of Self.)
     */
    var _listeners: EventListenerStorage { get set }

}

public extension StdEmitterType {

    public func emit(event: EventType) {
        _emitHere(event)
    }

    public func _emitHere(event: EventType) {
        _listeners.emit(event)
        _emitAsNotification(event)
    }

    public func subscribe(listener: EventListenerType) {
        _listeners.subscribe(listener)
    }

    public func unsubscribe(listener: EventListenerType) {
        _listeners.unsubscribe(listener)
    }

}
