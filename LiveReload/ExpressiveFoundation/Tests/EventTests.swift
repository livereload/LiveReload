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

import XCTest
@testable import ExpressiveFoundation

class Foo: StdEmitterType {

    var _listeners = EventListenerStorage()

    struct DidChange: EventType {
        let newValue: Int
    }

    struct DidBoo: EventTypeWithNotification {
        static let notificationName = "FooDidBoo"
        let newValue: Int
    }

    var value: Int = 1

    func change() {
        value += 1
        emit(DidChange(newValue: value))
        emit(DidBoo(newValue: value))
    }

}


class ObservationTests: XCTestCase {

    var e2: XCTestExpectation!

    func testBlockListener() {
        let e1 = expectationWithDescription("Instance")

        let foo = Foo()
        var o = Observation()

        o += foo.subscribe { (event: Foo.DidChange, sender) in
            XCTAssertEqual(event.newValue, 2)
            e1.fulfill()
        }

        foo.change()

        waitForExpectationsWithTimeout(0.1, handler: nil)
    }

    func testMethodListenerWith2ArgsSpecific() {
        e2 = expectationWithDescription("Method")

        let foo = Foo()
        var o = Observation()

        o += foo.subscribe(self, ObservationTests.fooDidChange2s)
        foo.change()

        waitForExpectationsWithTimeout(0.1, handler: nil)
    }

    func testMethodListenerWith2Args() {
        e2 = expectationWithDescription("Method")

        let foo = Foo()
        var o = Observation()

        o += foo.subscribe(self, ObservationTests.fooDidChange2)
        foo.change()

        waitForExpectationsWithTimeout(0.1, handler: nil)
    }

    func testMethodListenerWith1Arg() {
        e2 = expectationWithDescription("Method")

        let foo = Foo()
        var o = Observation()

        o += foo.subscribe(self, ObservationTests.fooDidChange1)
        foo.change()

        waitForExpectationsWithTimeout(0.1, handler: nil)
    }

    func fooDidChange2s(event: Foo.DidChange, sender: Foo) {
        XCTAssertEqual(event.newValue, 2)
        e2.fulfill()
    }

    func fooDidChange2(event: Foo.DidChange, sender: EmitterType) {
        XCTAssertEqual(event.newValue, 2)
        e2.fulfill()
    }

    func fooDidChange1(event: Foo.DidChange) {
        XCTAssertEqual(event.newValue, 2)
        e2.fulfill()
    }

    func testNotificationBridging() {
        let foo = Foo()

        expectationForNotification(Foo.DidBoo.notificationName, object: foo, handler: nil)

        foo.change()

        waitForExpectationsWithTimeout(0.1, handler: nil)
    }

    func testMultiple() {
        var log: [String] = []
        let e1 = expectationWithDescription("Instance")
        var o = Observation()

        let foo = Foo()

        o += foo.subscribe { (event: Foo.DidChange, sender) in
            log.append("Foo.DidChange(\(event.newValue))")
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_MSEC) * 100), dispatch_get_main_queue()) {
            log.append("timeout v=\(foo.value)")
            e1.fulfill()
        }

        foo.change()
        foo.change()

        waitForExpectationsWithTimeout(0.1) { err in
            XCTAssertEqual(log, ["Foo.DidChange(2)", "Foo.DidChange(3)", "timeout v=3"])
        }
    }

    func testSubscribeOnce() {
        var log: [String] = []
        let e1 = expectationWithDescription("Instance")

        let foo = Foo()

        foo.subscribeOnce { (event: Foo.DidChange, sender) in
            log.append("Foo.DidChange(\(event.newValue))")

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_MSEC) * 100), dispatch_get_main_queue()) {
                log.append("timeout v=\(foo.value)")
                e1.fulfill()
            }
        }

        foo.change()
        foo.change()

        waitForExpectationsWithTimeout(0.1) { err in
            XCTAssertEqual(log, ["Foo.DidChange(2)", "timeout v=3"])
        }
    }

    func testListenerNotRetained() {
        var log: [String] = []
        let e1 = expectationWithDescription("timeout")

        let foo = Foo()

        let _ = foo.subscribe { (event: Foo.DidChange, sender) in
            log.append("Foo.DidChange(\(event.newValue))")
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_MSEC) * 100), dispatch_get_main_queue()) {
            log.append("timeout v=\(foo.value)")
            e1.fulfill()
        }

        foo.change()
        foo.change()

        waitForExpectationsWithTimeout(0.1) { err in
            XCTAssertEqual(log, ["timeout v=3"])
        }
    }

}
