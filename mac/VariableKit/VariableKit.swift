import Foundation

public enum VariableFoldingBehavior {
    case Folded
    case Accumulated
}

public enum VariableScope {
    case File
    case Project
}

public struct VariableDefinition {
    public let name: String
    public let scope: VariableScope
    public let foldingBehavior: VariableFoldingBehavior

    public init(name: String, scope: VariableScope, foldingBehavior: VariableFoldingBehavior) {
        self.name = name
        self.scope = scope
        self.foldingBehavior = foldingBehavior
    }
}

public final class EvidenceSource {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

public final class VariableSet {

    public let variables: [Variable]
    public let sources: [EvidenceSource]
    public let variablesByName: [String: Variable]

    public init(variableDefinitions: [VariableDefinition], sources: [EvidenceSource]) {
        var nextIndex = 0
        variables = variableDefinitions.map { Variable(definition: $0, index: nextIndex++) }
        self.sources = sources

        var variablesByName = [String: Variable]()
        for variable in variables {
            variablesByName[variable.name] = variable
        }
        self.variablesByName = variablesByName
    }

    public func lookupVariable(#name: String) -> Variable? {
        return variablesByName[name]
    }

    public func lookupVariable(#definition: VariableDefinition) -> Variable? {
        return lookupVariable(name: definition.name)
    }

    public func newValueSet(#scope: VariableScope) -> ValueSet {
        return ValueSet(variableSet: self, scope: scope)
    }

}

public final class Variable {

    public let definition: VariableDefinition
    public let index: Int

    private init(definition: VariableDefinition, index: Int) {
        self.definition = definition
        self.index = index
    }

    public var name: String {
        return definition.name
    }

    public var scope: VariableScope {
        return definition.scope
    }

}

public struct Evidence {
    public let variable: Variable
    public let source: EvidenceSource
    public let value: Any
    public let priority: Int
    public let reason: String

    public init(variable: Variable, source: EvidenceSource, value: Any, priority: Int, reason: String) {
        self.variable = variable
        self.source = source
        self.value = value
        self.priority = priority
        self.reason = reason
    }
}


public final class ValueSet {

    public let variableSet: VariableSet
    public let scope: VariableScope
    private var evidence: [Evidence] = []

    private init(variableSet: VariableSet, scope: VariableScope) {
        self.variableSet = variableSet
        self.scope = scope
    }

    public func getEvidence(#variable: Variable) -> [Evidence] {
        return evidence.filter { $0.variable === variable }
    }

    public func getFolded(#variable: Variable) -> Any? {
        let evidence = getEvidence(variable: variable)
        if evidence.count > 0 {
            return evidence[0].value
        } else {
            return nil
        }
    }

    public func getFolded(#variable: Variable, defaultValue: Any) -> Any {
        if let value = getFolded(variable: variable) {
            return value
        } else {
            return defaultValue
        }
    }

    public func replaceEvidenceList(#source: EvidenceSource, newEvidence: [Evidence]) {
        evidence = evidence.filter { $0.source !== source }
        evidence.extend(newEvidence)
        evidence.sort { $0.priority > $1.priority }
    }

    public func replaceEvidence(#source: EvidenceSource, newEvidence: Evidence) {
        self.replaceEvidenceList(source: source, newEvidence: [newEvidence])
    }

    public func replaceEvidence(#source: EvidenceSource, variable: Variable, value: Any, priority: Int = 0, reason: String) {
        self.replaceEvidence(source: source, newEvidence: Evidence(variable: variable, source: source, value: value, priority: priority, reason: reason))
    }
}
