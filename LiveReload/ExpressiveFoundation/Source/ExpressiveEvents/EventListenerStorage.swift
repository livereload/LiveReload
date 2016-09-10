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

public struct EventListenerStorage {

    private var subscriptionsByEventType: [ObjectIdentifier: [EventSubscription]] = [:]

    public init() {
    }

    func emit(payload: EventType) {
        let eventType = payload.dynamicType
        let oid = ObjectIdentifier(eventType)
        if let subscriptions = subscriptionsByEventType[oid] {
            for subscription in subscriptions {
                if let listener = subscription.listener {
                    if listener.eventType == eventType {
                        listener.handle(payload)
                    }
                }
            }
        }
    }

    mutating func subscribe(listener: EventListenerType) {
        let oid = ObjectIdentifier(listener.eventType)
        let subscription = EventSubscription(listener)
        if subscriptionsByEventType[oid] != nil {
            subscriptionsByEventType[oid]!.append(subscription)
        } else {
            subscriptionsByEventType[oid] = [subscription]
        }
    }

    mutating func unsubscribe(listener: EventListenerType) {
        let oid = ObjectIdentifier(listener.eventType)
        if let subscriptions = subscriptionsByEventType[oid] {
            if let idx = subscriptions.indexOf({ $0.listener === listener }) {
                subscriptionsByEventType[oid]!.removeAtIndex(idx)
            }
        }
    }

}

private struct EventSubscription {

    private weak var listener: EventListenerType?

    private init(_ listener: EventListenerType) {
        self.listener = listener
    }
    
}

