import Foundation

public class Bus {
    
    private let queue = dispatch_get_main_queue()
    
    private let isVerbose = true

    private var registeredTags: [Tag] = []
    private var registeredTagMap: [Tag: Int] = [:]
    
    private var nextChangeSetId: UInt64 = 1
    private var changeSet: ChangeSet?
    
    private var sources: [SourceRef] = []
    private var sourcesByDependencies: [Tag: [SourceRef]] = [:]

    public init() {
    }
    
    public func add(source: Source) {
        for tag in source.dependentTags {
            if !isKnown(tag) {
                fatalError("Attempting to add a source \(source) dependent on unregistered tag \(tag)")
            }
        }
        for tag in source.affectedTags {
            register(tag)
        }

        let ref = SourceRef(source: source)
        sources.append(ref)
        
        for tag in source.dependentTags {
            sourcesByDependencies[tag]!.append(ref)
        }

        update(ref, reason: .Loading)
    }
    
    @warn_unused_result
    public func addConsumer(dependentTags: [Tag], block: (ChangeReason) -> Void) -> BlockConsumer {
        return BlockConsumer(dependentTags: dependentTags, block: block)
    }
    
    public func register(tag: Tag) {
        if self.registeredTagMap[tag] == nil {
            self.registeredTagMap[tag] = self.registeredTags.count
            self.registeredTags.append(tag)
            self.sourcesByDependencies[tag] = []
        }
    }
    
    public func perform(change: Change, reason: ChangeReason) {
        if self.isVerbose {
            print("Bus: performing change affecting \(change.affectedTags)")
        }
        change.perform()
        for tag in change.affectedTags {
            _changed(tag, reason: reason)
        }
    }
    
    public func changed(tag: Tag, reason: ChangeReason) {
        dispatch_async(queue) {
            self._changed(tag, reason: reason)
        }
    }
    
    private func isKnown(tag: Tag) -> Bool {
        return registeredTagMap[tag] != nil
    }
    
    private func _changed(tag: Tag, reason: ChangeReason) {
        guard isKnown(tag) else {
            fatalError("Attempting to produce change on unregistered tag \(tag)")
        }

        let cs = openChangeSet()
        cs.reason = cs.reason.merge(reason)

        if !cs.changedTags.contains(tag) {
            cs.changedTags.insert(tag)
            if isVerbose {
                print("Bus: changed \(tag)")
            }
        }
    }

    private func openChangeSet() -> ChangeSet {
        if let changeSet = changeSet {
            return changeSet
        }
        
        let cs = ChangeSet(id: nextChangeSetId, sources: sources)
        self.changeSet = cs
        nextChangeSetId += 1

        if self.isVerbose {
            print("Bus: opened change set \(cs)")
        }
        
        performNextStepInChangeSetAsynchrously()
        
        return cs
    }

    private func performNextStepInChangeSetAsynchrously() {
        dispatch_async(queue) {
            self.performNextStepInChangeSet()
        }
    }
    
    private func performNextStepInChangeSet() {
        guard let cs = self.changeSet else {
            fatalError("Bus: performNextStepInChangeSet called with no changeset")
        }
        
        repeat {
            if cs.sources.isEmpty {
                if self.isVerbose {
                    print("Bus: closed change set \(cs)")
                }
                self.changeSet = nil
                return
            }

            let ref = cs.sources.removeFirst()
            if ref.shouldBeNotified(for: cs) {
                update(ref, reason: cs.reason)
                performNextStepInChangeSetAsynchrously()
                return
            }
        } while true
    }
    
    private func update(sourceRef: SourceRef, reason: ChangeReason) {
        if let source = sourceRef.source {
            if self.isVerbose {
                print("Bus: updating \(source)")
            }
            let session = UpdateSession(bus: self, source: sourceRef, reason: reason)
            source.update(session)
            session.done()
        }
    }
    
    private func compactSources() {
        sources = sources.filter { $0.isAlive }
    }

    @warn_unused_result
    public func subscribe<T: AnyObject>(to tag: Tag, _ object: T, _ method: (T) -> (ChangeSet) -> Void) -> NSObjectProtocol {
        weak var weakObject = object
        return NSNotificationCenter.defaultCenter().addObserverForName(tag.changeNotificationName, object: nil, queue: nil) { (notification) in
            let cs = notification.object as! ChangeSet
            if let object = weakObject {
                method(object)(cs)
            }
        }
    }
    
    @warn_unused_result
    public func subscribe<T: AnyObject>(to tag: Tag, _ object: T, _ method: (T) -> (ChangeReason) -> Void) -> NSObjectProtocol {
        weak var weakObject = object
        return NSNotificationCenter.defaultCenter().addObserverForName(tag.changeNotificationName, object: nil, queue: nil) { (notification) in
            let cs = notification.object as! ChangeSet
            if let object = weakObject {
                method(object)(cs.reason)
            }
        }
    }
    
}

public class ChangeSet {
    
    public let id: UInt64
    
    private var sources: [SourceRef]

    private var changedTags = Set<Tag>()
    private var frozenTags = Set<Tag>()

    public private(set) var reason: ChangeReason = .Loading
    
    private init(id: UInt64, sources: [SourceRef]) {
        self.id = id
        self.sources = sources
    }
    
    private func freeze<S : SequenceType where S.Generator.Element == Tag>(tags: S) {
        frozenTags.unionInPlace(tags)
    }

}

public class UpdateSession {

    public let bus: Bus
    private let source: SourceRef
    public let reason: ChangeReason
    private var isClosed = false

    private init(bus: Bus, source: SourceRef, reason: ChangeReason) {
        self.bus = bus
        self.source = source
        self.reason = reason
    }
    
    public func changed(tag: Tag) {
        guard !isClosed else {
            fatalError("changed() call on a closed update session")
        }
        bus.changed(tag, reason: reason)
    }
    
    public func done() {
        if !isClosed {
            isClosed = true
        }
    }
    
}

extension ChangeSet: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let tags = changedTags.map {$0.name}.joinWithSeparator(",")
        return "<#\(id) \(reason) \(tags)>"
    }
    
}

private class SourceRef {
    
    private weak var source: Source?
    
    private var isAlive: Bool {
        return source != nil
    }

    private var updateSession: UpdateSession?
    
    private var isInitialUpdatePending = true
    
    private init(source: Source) {
        self.source = source
    }
    
    private func shouldBeNotified(for cs: ChangeSet) -> Bool {
        guard let source = self.source else {
            return false
        }

        if isInitialUpdatePending {
            return true
        }

        for tag in source.dependentTags {
            if cs.changedTags.contains(tag) {
                return true
            }
        }
        
        return false
    }
    
}

extension SourceRef: Hashable {
    
    private var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
}

private func ==(lhs: SourceRef, rhs: SourceRef) -> Bool {
    return lhs === rhs
}

public protocol Source: class {
    
    func update(session: UpdateSession)
    
    var dependentTags: [Tag] { get }
    
    var affectedTags: [Tag] { get }
    
}

public protocol Change {
    
    var affectedTags: [Tag] { get }
    
    func perform()
    
}

public class BlockConsumer: Source {

    public let dependentTags: [Tag]
    private let block: (ChangeReason) -> Void

    public init(dependentTags: [Tag], block: (ChangeReason) -> Void) {
        self.dependentTags = dependentTags
        self.block = block
    }

    public func update(session: UpdateSession) {
        block(session.reason)
    }
    
    public var affectedTags: [Tag] {
        return []
    }

}
