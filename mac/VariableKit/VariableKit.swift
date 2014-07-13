import Foundation

enum VariableFoldingBehavior {
    case Folded
    case Accumulated
}

enum VariableScope {
    case File
    case Project
}

struct VariableDefinition {
    let name: String
    let scope: VariableScope
    let foldingBehavior: VariableFoldingBehavior
}

@final class EvidenceSource {
    let name: String

    init(name: String) {
        self.name = name
    }
}

@final class VariableSet {

    let variables: [Variable]
    let sources: [EvidenceSource]
    let variablesByName: [String: Variable]

    init(variableDefinitions: [VariableDefinition], sources: [EvidenceSource]) {
        var nextIndex = 0
        variables = variableDefinitions.map { Variable(definition: $0, index: nextIndex++) }
        self.sources = sources

        var variablesByName = [String: Variable]()
        for variable in variables {
            variablesByName[variable.name] = variable
        }
        self.variablesByName = variablesByName
    }

    func lookupVariable(#name: String) -> Variable? {
        return variablesByName[name]
    }

    func lookupVariable(#definition: VariableDefinition) -> Variable? {
        return lookupVariable(name: definition.name)
    }

    func newValueSet(#scope: VariableScope) -> ValueSet {
        return ValueSet(variableSet: self, scope: scope)
    }

}

@final class Variable {

    let definition: VariableDefinition
    let index: Int

    init(definition: VariableDefinition, index: Int) {
        self.definition = definition
        self.index = index
    }

    var name: String {
        return definition.name
    }

    var scope: VariableScope {
        return definition.scope
    }

}

struct Evidence {
    let variable: Variable
    let source: EvidenceSource
    let value: Any
    let priority: Int
    let reason: String
}


@final class ValueSet {

    let variableSet: VariableSet
    let scope: VariableScope
    var evidence: [Evidence] = []

    init(variableSet: VariableSet, scope: VariableScope) {
        self.variableSet = variableSet
        self.scope = scope
    }

    func getEvidence(#variable: Variable) -> [Evidence] {
        return evidence.filter { $0.variable === variable }
    }

    func getFolded(#variable: Variable) -> Any? {
        let evidence = getEvidence(variable: variable)
        if evidence.count > 0 {
            return evidence[0].value
        } else {
            return nil
        }
    }

    func getFolded(#variable: Variable, defaultValue: Any) -> Any {
        if let value = getFolded(variable: variable) {
            return value
        } else {
            return defaultValue
        }
    }

    func replaceEvidenceList(#source: EvidenceSource, newEvidence: [Evidence]) {
        evidence = evidence.filter { $0.source !== source }
        evidence.extend(newEvidence)
        evidence.sort { $0.priority > $1.priority }
    }

    func replaceEvidence(#source: EvidenceSource, newEvidence: Evidence) {
        self.replaceEvidenceList(source: source, newEvidence: [newEvidence])
    }

    func replaceEvidence(#source: EvidenceSource, variable: Variable, value: Any, priority: Int = 0, reason: String) {
        self.replaceEvidence(source: source, newEvidence: Evidence(variable: variable, source: source, value: value, priority: priority, reason: reason))
    }
}
