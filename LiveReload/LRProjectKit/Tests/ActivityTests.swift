import XCTest
import ExpressiveFoundation
@testable import LRProjectKit
import PromiseKit

struct TestRequest: RequestType, CustomStringConvertible {

    let value: Int

    let user: Bool

    func merge(other: TestRequest, isRunning: Bool) -> TestRequest? {
        if isRunning && (self.value != other.value) {
            return nil
        }
        return TestRequest(value: max(self.value, other.value), user: self.user || other.user)
    }

    var description: String {
        let u = (user ? "y" : "n")
        return "<\(value) \(u)>"
    }

}

func ==(lhs: TestRequest, rhs: TestRequest) -> Bool {
    return (lhs.value == rhs.value) && (lhs.user == rhs.user)
}

public class Something: StdEmitterType {

    public var log: [String] = []

    var processable: Processor<TestRequest> {
        return _processing
    }

    init() {
        _processing.initializeWithHost(self, emitsEventsOnHost: true, performs: Something.loadItems)
    }

    func perform(request: TestRequest) {
        _processing.schedule(request)
    }

    private func loadItems(request: TestRequest, context: OperationContext) -> Promise<Void> {
        log.append("start \(request)")
        return Promise(())
    }

    private let _processing = ProcessorImpl<TestRequest>()

    public var _listeners = EventListenerStorage()

}

class ActivityTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSingleRequest() {
        var o = Observation()
        let smt = Something()

        let e = expectationWithDescription("ProcessableBatchDidFinish")
        o += smt.subscribe { (event: ProcessableBatchDidFinish, sender) in
            smt.log.append("batch finished")
            e.fulfill()
        }

        smt.perform(TestRequest(value: 1, user: false))
        XCTAssertEqual(smt.log, [])  // start must be delayed until the next run loop iteration
        XCTAssertEqual(smt.processable.isRunning, true)  // but must be reported as running

        waitForExpectationsWithTimeout(0.1) { err in
            XCTAssertEqual(smt.processable.isRunning, false)
            XCTAssertEqual(smt.log, ["start <1 n>", "batch finished"])
        }
    }

    func testMerging() {
        var o = Observation()
        let smt = Something()

        let e = expectationWithDescription("ProcessableBatchDidFinish")
        o += smt.subscribe { (event: ProcessableBatchDidFinish, sender) in
            smt.log.append("batch finished")
            e.fulfill()
        }

        smt.perform(TestRequest(value: 1, user: false))
        smt.perform(TestRequest(value: 2, user: false))
        smt.perform(TestRequest(value: 1, user: true))

        waitForExpectationsWithTimeout(0.1) { err in
            XCTAssertEqual(smt.log, ["start <2 y>", "batch finished"])
        }
    }

    func testConditionalMerging() {
        var o = Observation()
        let smt = Something()

        let e = expectationWithDescription("ProcessableBatchDidFinish")
        o += smt.subscribe { (event: ProcessableBatchDidFinish, sender) in
            smt.log.append("batch finished")
            e.fulfill()
        }
        o += smt.subscribe { (event: OperationDidStart, sender) in
            let request = event.request as! TestRequest
            if request == TestRequest(value: 1, user: false) {
                smt.perform(TestRequest(value: 2, user: false))
                smt.perform(TestRequest(value: 1, user: true))
            }
        }

        smt.perform(TestRequest(value: 1, user: false))

        waitForExpectationsWithTimeout(0.1) { err in
            XCTAssertEqual(smt.log, ["start <1 y>", "start <2 n>", "batch finished"])
        }
    }

    func testDisposedBeforeInitialization() {
        var o = Observation()
        let pr = ProcessorImpl<TestRequest>()
        var log: [String] = []

        let e = expectationWithDescription("ProcessableBatchDidFinish")
        o += pr.subscribe { (event: OperationDidFinish, sender) in
            if let error = event.error {
                log.append("error: \(error)")
            }
        }
        o += pr.subscribe { (event: ProcessableBatchDidFinish, sender) in
            log.append("batch finished")
            e.fulfill()
        }

        pr.schedule(TestRequest(value: 1, user: false))
        XCTAssertEqual(log, [])
        XCTAssertEqual(pr.isRunning, true)

        pr.dispose()

        waitForExpectationsWithTimeout(0.1) { err in
            if err != nil { return }
            XCTAssertEqual(pr.isRunning, false)
            XCTAssertEqual(log, ["error: ProcessorDisposed", "batch finished"])
        }
    }

    func testGroup() {
        var o = Observation()
        let foo = Something()
        let bar = Something()
        let group = ProcessingGroup()
        group.add([foo.processable, bar.processable])

        let e = expectationWithDescription("ProcessableBatchDidFinish")
        o += group.subscribe { (event: ProcessableBatchDidFinish, sender) in
            e.fulfill()
        }

        foo.perform(TestRequest(value: 1, user: false))
        XCTAssertEqual(group.isRunning, true)

        foo.perform(TestRequest(value: 2, user: false))
        foo.perform(TestRequest(value: 1, user: true))
        bar.perform(TestRequest(value: 3, user: false))
        bar.perform(TestRequest(value: 4, user: false))

        XCTAssertEqual(group.isRunning, true)

        waitForExpectationsWithTimeout(0.1) { err in
            XCTAssertEqual(group.isRunning, false)
            XCTAssertEqual(foo.log, ["start <2 y>"])
            XCTAssertEqual(bar.log, ["start <4 n>"])
        }
    }

}
