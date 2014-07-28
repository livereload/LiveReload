import Foundation
import VariableKit

struct AnalyzerDefinition {
    let scope: VariableScope
    let pathSpec: ATPathSpec
}

class Analyzer {

    let project: Project
    let definition: AnalyzerDefinition
    let scope: VariableScope
    let evidenceSource: EvidenceSource
    var pathSpec: ATPathSpec

    init(project: Project, definition: AnalyzerDefinition) {
        self.project = project
        self.definition = definition
        self.scope = definition.scope
        self.pathSpec = definition.pathSpec  // TODO: resolve references in the definition
        evidenceSource = EvidenceSource(name: "Analyzer X")  // TODO: use a meaningful name
    }

}

protocol AnalyzerHost {

//    let variableSet: VariableSet

}
