import Cocoa
import XCTest
import SwiftyFoundation

private class Counter {
    public var value = 0
}

private class Foo {
    private var o = Observation()
    private let counter: Counter

    init(counter: Counter) {
        self.counter = counter
        o.on(BarDidChangeNotification, self, Foo.somethingDidChange)
    }

    private func somethingDidChange() {
        ++counter.value
    }
}

private let BarDidChangeNotification = "BarDidChange"
private class Bar: NSObject {
}

class ObservationTests: XCTestCase {

    func testObservation() {
        let counter = Counter()

        var foo: Foo? = Foo(counter: counter)
        XCTAssertEqual(counter.value, 0)

        let bar = Bar()
        bar.postNotification(BarDidChangeNotification)
        XCTAssertEqual(counter.value, 1)

        foo = nil
        bar.postNotification(BarDidChangeNotification)
        XCTAssertEqual(counter.value, 1)
    }

}
