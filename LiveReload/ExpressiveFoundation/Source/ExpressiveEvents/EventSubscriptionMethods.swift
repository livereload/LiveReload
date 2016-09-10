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


// MARK: - Normal subscriptions ("subscribe")

public extension EmitterType {

    @warn_unused_result
    public func subscribe<Event: EventType>(block: (Event, EmitterType) -> Void) -> ListenerType {
        return BlockNormalEventListener(self, block)
    }

    @warn_unused_result
    public func subscribe<Event: EventType, Target: AnyObject>(target: Target, _ block: (Target) -> (Event) -> Void) -> ListenerType {
        return Method1ArgNormalEventListener(self, target, block)
    }

    @warn_unused_result
    public func subscribe<Event: EventType, Target: AnyObject>(target: Target, _ block: (Target) -> (Event, EmitterType) -> Void) -> ListenerType {
        return Method2ArgSpecificNormalEmitterEventListener(self, target, block)
    }

}

// this method is not safe to use on any EventEmitter because in case of
// event delegation, the actual emitter type might not be Self
public extension StdEmitterType {

    @warn_unused_result
    public func subscribe<Event: EventType, Target: AnyObject>(target: Target, _ block: (Target) -> (Event, Self) -> Void) -> ListenerType {
        return Method2ArgSpecificNormalEmitterEventListener(self, target, block)
    }

}


// MARK: - One-shot subscriptions ("subscribeOnce")

public extension EmitterType {

    public func subscribeOnce<Event: EventType>(block: (Event, EmitterType) -> Void) {
        let _ = BlockOneShotEventListener(self, block)
    }

    public func subscribeOnce<Event: EventType, Target: AnyObject>(target: Target, _ block: (Target) -> (Event) -> Void) {
        let _ = Method1ArgOneShotEventListener(self, target, block)
    }

    public func subscribeOnce<Event: EventType, Target: AnyObject>(target: Target, _ block: (Target) -> (Event, EmitterType) -> Void) {
        let _ = Method2ArgSpecificOneShotEmitterEventListener(self, target, block)
    }

}

// this method is not safe to use on any EventEmitter because in case of
// event delegation, the actual emitter type might not be Self
public extension StdEmitterType {

    public func subscribeOnce<Event: EventType, Target: AnyObject>(target: Target, _ block: (Target) -> (Event, Self) -> Void) {
        let _ = Method2ArgSpecificOneShotEmitterEventListener(self, target, block)
    }
    
}


// MARK: - EventListenerType implementations (base class)

private class BaseEventListener<Event: EventType>: EventListenerType {

    var eventType: EventType.Type {
        return Event.self
    }

    func handle(payload: EventType) {
        fatalError("must override")
    }
    
}


// MARK: - EventListenerType implementations (normal listeners)

private class NormalEventListener<Event: EventType>: BaseEventListener<Event> {

    private weak var emitter: EmitterType?

    init(_ emitter: EmitterType) {
        self.emitter = emitter
        super.init()
        emitter.subscribe(self)
    }

    deinit {
        if let emitter = emitter {
            emitter.unsubscribe(self)
        }
    }

}

private final class BlockNormalEventListener<Event: EventType>: NormalEventListener<Event> {

    private let block: (Event, EmitterType) -> Void

    init(_ emitter: EmitterType, _ block: (Event, EmitterType) -> Void) {
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        if let emitter = emitter {
            block(payload as! Event, emitter)
        }
    }

}

private final class Method2ArgSpecificNormalEmitterEventListener<Event: EventType, Emitter: EmitterType, Target: AnyObject>: NormalEventListener<Event> {

    private weak var target: Target?

    private let block: (Target) -> (Event, Emitter) -> Void

    init(_ emitter: Emitter, _ target: Target, _ block: (Target) -> (Event, Emitter) -> Void) {
        self.target = target
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        // emitter might not be an instance of Emitter in case _listeners is delegated
        if let target = target, emitter = emitter as? Emitter {
            block(target)(payload as! Event, emitter)
        }
    }

}

private final class Method2ArgNormalEventListener<Event: EventType, Target: AnyObject>: NormalEventListener<Event> {

    private weak var target: Target?

    private let block: (Target) -> (Event, EmitterType) -> Void

    init(_ emitter: EmitterType, _ target: Target, _ block: (Target) -> (Event, EmitterType) -> Void) {
        self.target = target
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        if let target = target, emitter = emitter {
            block(target)(payload as! Event, emitter)
        }
    }

}

private final class Method1ArgNormalEventListener<Event: EventType, Target: AnyObject>: NormalEventListener<Event> {

    private weak var target: Target?

    private let block: (Target) -> (Event) -> Void

    init(_ emitter: EmitterType, _ target: Target, _ block: (Target) -> (Event) -> Void) {
        self.target = target
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        if let target = target {
            block(target)(payload as! Event)
        }
    }
    
}


// MARK: - EventListenerType implementations (one-shot listeners)

private class OneShotEventListener<Event: EventType>: BaseEventListener<Event> {

    private weak var emitter: EmitterType?

    private var referenceCycle: AnyObject?

    init(_ emitter: EmitterType) {
        self.emitter = emitter
        super.init()
        emitter.subscribe(self)
        referenceCycle = self
    }

    private func handled() {
        if referenceCycle != nil {
            if let emitter = emitter {
                emitter.unsubscribe(self)
            }
            referenceCycle = nil
        }
    }

}

private final class BlockOneShotEventListener<Event: EventType>: OneShotEventListener<Event> {

    private let block: (Event, EmitterType) -> Void

    init(_ emitter: EmitterType, _ block: (Event, EmitterType) -> Void) {
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        if let emitter = emitter {
            block(payload as! Event, emitter)
        }
        handled()
    }

}

private final class Method2ArgSpecificOneShotEmitterEventListener<Event: EventType, Emitter: EmitterType, Target: AnyObject>: OneShotEventListener<Event> {

    private weak var target: Target?

    private let block: (Target) -> (Event, Emitter) -> Void

    init(_ emitter: Emitter, _ target: Target, _ block: (Target) -> (Event, Emitter) -> Void) {
        self.target = target
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        // emitter might not be an instance of Emitter in case _listeners is delegated
        if let target = target, emitter = emitter as? Emitter {
            block(target)(payload as! Event, emitter)
        }
        handled()
    }

}

private final class Method2ArgOneShotEventListener<Event: EventType, Target: AnyObject>: OneShotEventListener<Event> {

    private weak var target: Target?

    private let block: (Target) -> (Event, EmitterType) -> Void

    init(_ emitter: EmitterType, _ target: Target, _ block: (Target) -> (Event, EmitterType) -> Void) {
        self.target = target
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        if let target = target, emitter = emitter {
            block(target)(payload as! Event, emitter)
            handled()
        }
        handled()
    }

}

private final class Method1ArgOneShotEventListener<Event: EventType, Target: AnyObject>: OneShotEventListener<Event> {

    private weak var target: Target?

    private let block: (Target) -> (Event) -> Void

    init(_ emitter: EmitterType, _ target: Target, _ block: (Target) -> (Event) -> Void) {
        self.target = target
        self.block = block
        super.init(emitter)
    }

    override func handle(payload: EventType) {
        if let target = target {
            block(target)(payload as! Event)
        }
        handled()
    }
    
}
