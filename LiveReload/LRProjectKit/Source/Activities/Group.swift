import Foundation
import ExpressiveFoundation
import PromiseKit

public class ProcessingGroup: Processable, StdEmitterType {

    private var emitsEventsOnHost: Bool = false

    private weak var host: EmitterType?

    private var subgroups: [ProcessingSubgroup] = []

    public private(set) var isRunning: Bool = false

    public private(set) var children: [Processable] = []

    public private(set) var disposed: Bool = false

    private var childrenListeners: [ObjectIdentifier: [(updatable: Processable, listener: ListenerType)]] = [:]

    public init() {
    }

    public func initializeWithHost<Host: EmitterType>(host: Host, emitsEventsOnHost: Bool) {
        if self.host != nil {
            fatalError("Can only invoke initializeWithHost once")
        }
        self.host = host
        self.emitsEventsOnHost = emitsEventsOnHost
    }

    public func dispose() {
        disposed = true
        childrenListeners = [:]  // stop listening to changes
    }

    public func emit(event: EventType) {
        _emitHere(event)
        if emitsEventsOnHost, let host = host {
            host.emit(event)
        }
    }

    public func add(item: Processable) {
        add([item])
    }

    public func add(items: [Processable]) {
        add(StaticProcessingSubgroup(items))
    }

    public func add<Host: AnyObject>(host: Host, method: (Host) -> () -> [Processable]) {
        add(DynamicProcessingSubgroup(host, method))
    }

    private func add(subgroup: ProcessingSubgroup) {
        subgroups.append(subgroup)
        refreshChildren()
    }

    public func refreshChildren() {
        if disposed {
            return  // don't add any children
        }

        let newChildren = subgroups.flatMap { $0.items }
        self.children = newChildren

        let oldMap = childrenListeners
        var newMap = [ObjectIdentifier: [(updatable: Processable, listener: ListenerType)]]()

        #if true
            print("\(self): now has \(newChildren.count) children")
        #endif

        for child in newChildren {
            let oid = ObjectIdentifier(child)

            let listener: ListenerType
            if let old = oldMap[oid]?.find({ $0.updatable === child })?.listener {
                listener = old
            } else {
                listener = child.subscribe(self, ProcessingGroup.childStateDidChange)
                #if true
                    print("\(self): subscribed to \(child)")
                #endif
            }

            if newMap[oid] == nil {
                newMap[oid] = []
            }
            newMap[oid]!.append((child, listener))
        }

        refreshState(children: newChildren)

        childrenListeners = newMap
    }

    private func refreshState(children children: [Processable]) {
        let prev = isRunning
        isRunning = children.contains { $0.isRunning }
        if prev != isRunning {
            emit(ProcessableStateDidChange(isRunningChanged: true))
            if !isRunning {
                emit(ProcessableBatchDidFinish())
            }
        }
    }

    private func childStateDidChange(event: ProcessableStateDidChange) {
        if !event.isRunningChanged {
            return
        }
        print("\(self): noticed state change of a child")
        refreshState(children: self.children)
    }

    public var _listeners = EventListenerStorage()

}

private protocol ProcessingSubgroup: AnyObject {

    var items: [Processable] { get }

}

private class StaticProcessingSubgroup: ProcessingSubgroup {

    private let items: [Processable]

    private init(_ items: [Processable]) {
        self.items = items
    }

}

private class DynamicProcessingSubgroup<Host: AnyObject>: ProcessingSubgroup {

    private weak var host: Host?
    private let method: (Host) -> () -> [Processable]

    private init(_ host: Host, _ method: (Host) -> () -> [Processable]) {
        self.host = host
        self.method = method
    }
    
    private var items: [Processable] {
        if let host = host {
            return method(host)()
        } else {
            return []
        }
    }
    
}
