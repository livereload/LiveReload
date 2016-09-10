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

/**
 An event that can be emitted by `EmitterType`s.

 In the simplest case, an event can be an empty struct. You can even declare it within the relevant class:

 ```
 class Foo: StdEmitterType {
     struct SomethingDidHappen: EventType {
     }

     func doSomething() {
         emit(SomethingDidHappen())
     }

     var _listeners = EventListenerStorage()
 }

 func test() {
     var o = Observation()
     var foo = Foo()
     o += foo.subscribe { (event: SomethingDidHappen, emitter) in
         print("did happen")
     }
     foo.doSomething()  // prints "did happen"
 }
 ```

 You may want to add additional details:

 ```
 struct SomethingDidHappen: EventType {
     let reason: String
 }

 class Foo: StdEmitterType {
     func doSomething() {
         emit(SomethingDidHappen("no reason at all"))
     }
     var _listeners = EventListenerStorage()
 }

 func test() {
     var o = Observation()
     var foo = Foo()
     o += foo.subscribe { (event: SomethingDidHappen, emitter) in
         print("did happen for \(event.reason)")
     }
     foo.doSomething()  // prints "did happen for no reason at all"
 }
 ```

 An event can also be a class. For example, this may be useful if you want the event handlers to be able to return a value:

 ```
 class SomethingWillHappen: EventType {
     var allow: Bool = true
 }

 class Foo: StdEmitterType {
     func doSomething() {
     let event = SomethingWillHappen()
     emit(event)
     if event.allow {
         print("actually doing it")
     } else {
         print("forbidden")
     }
 }

 var _listeners = EventListenerStorage()
 }

 func test() {
     var o = Observation()
     var foo = Foo()
     o += foo.subscribe { (event: SomethingWillHappen, emitter) in
         event.allow = false
     }
     foo.doSomething()  // prints "forbidden"
 }
 ```
*/
public protocol EventType {
}

public extension EventType {

    /// The name of the event for debugging and logging purposes. This returns a fully qualified type name like `MyModule.Foo.SomethingDidHappen`.
    public static var eventName: String {
        return String(reflecting: self)
    }

    public var eventName: String {
        return self.dynamicType.eventName
    }

}

/**
 An event that can be posted via `NSNotificationCenter`.
*/
public protocol EventTypeWithNotification: EventType {
    /// The notification center event name. By default this returns `eventName`, which is a fully qualified type name.
    static var notificationName: String { get }
    var notificationUserInfo: [String: AnyObject] { get }
}

public extension EventTypeWithNotification {
    static var notificationName: String {
        return eventName
    }
    var notificationUserInfo: [String: AnyObject] {
        return [:]
    }
}
