import Foundation
import ExpressiveFoundation
import PromiseKit

public class Group: Processable {

    private var subgroups: [Subgroup] = []

    public private(set) var isRunning: Bool = false

    public private(set) var children: [Processable] = []

    public private(set) var disposed: Bool = false

    private var childrenListeners: [ObjectIdentifier: [(updatable: Processable, listener: ListenerType)]] = [:]

    public init() {
    }

    public func dispose() {
        disposed = true
        childrenListeners = [:]  // stop listening to changes
    }

    public func add(item: Processable) {
        add([item])
    }

    public func add(items: [Processable]) {
        add(StaticSubgroup(items))
    }

    public func add<Host: AnyObject>(host: Host, method: (Host) -> () -> [Processable]) {
        add(DynamicSubgroup(host, method))
    }

    private func add(subgroup: Subgroup) {
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
                listener = child.subscribe(self, Group.childStateDidChange)
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

private protocol Subgroup: AnyObject {

    var items: [Processable] { get }

}

private class StaticSubgroup: Subgroup {

    private let items: [Processable]

    private init(_ items: [Processable]) {
        self.items = items
    }

}

private class DynamicSubgroup<Host: AnyObject>: Subgroup {

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
