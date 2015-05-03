import Foundation
import SwiftyFoundation
import PiiVersionKit
import ATPathSpec
import LRCommons;
import PackageManagerKit

public class Rulebook: NSObject {

    public static let didChangeNotification = "RulebookDidChange"

    public let actions: [Action]
    public let contextActions: [LRContextAction]
    public let project: ProjectContext

    public private(set) var rules: [Rule] = []

    private let actionsByIdentifier: [String: Action]
    private let contextActionsByIdentifier: [String: LRContextAction]

    public init(actions: [Action], project: ProjectContext) {
        self.actions = actions
        self.project = project

        actionsByIdentifier = indexBy(actions) { $0.identifier }
        contextActions = actions.map { LRContextAction(action: $0, project: project, resolutionContext: project.resolutionContext) }
        contextActionsByIdentifier = indexBy(contextActions) { $0.action.identifier }

        super.init()
    }

    public var resolutionContext: LRPackageResolutionContext {
        return project.resolutionContext
    }


    // MARK: Memento

    public var memento: [String: AnyObject] {
        get {
            var actionMementos: [AnyObject] = []
            for rule in rules {
                if rule.nonEmpty {
                    actionMementos.append(rule.theMemento)
                }
            }
            return ["rules": actionMementos]
        }
        set {
            let actionMementos: [[String: AnyObject]] = ArrayValue(newValue["rules"] ?? newValue["actions"], { $0 as? [String: AnyObject] }) ?? []
            rules = mapIf(actionMementos) { self.actionWithMemento($0) }
            
            didChange()
        }
    }


    // MARK: Filtered rules

    public var activeRules: [Rule] {
        return rules.filter { $0.nonEmpty && $0.enabled }
    }

    public var compilationRules: [Rule] {
        return rules.filter { $0.kind == ActionKind.Compiler }
    }

    public var filterRules: [Rule] {
        return rules.filter { $0.kind == ActionKind.Filter }
    }

    public var postprocRules: [Rule] {
        return rules.filter { $0.kind == ActionKind.Postproc }
    }


    // MARK: Modification methods

    public func removeObjectFromRules(atIndex index: Int) {
        rules.removeAtIndex(index)
        didChange()
    }

    public func addRuleWithPrototype(prototype: [String: AnyObject]) {
        if let rule = actionWithMemento(prototype) {
            rules.append(rule)
            didChange()
        } else {
            fatalError("Invalid rule prototype: \(prototype)")
        }
    }


    // MARK: Private modification helpers
    
    private func actionWithMemento(memento: [String: AnyObject]) -> Rule? {
        if let typeIdentifier = StringValue(memento["action"]) {
            if let type = contextActionsByIdentifier[typeIdentifier] {
                return type.newInstance(memento: memento)
            } else {
                return nil;
            }
        } else {
            return nil;
        }
    }

    private func didChange() {
        postNotification(Rulebook.didChangeNotification)
    }

}
