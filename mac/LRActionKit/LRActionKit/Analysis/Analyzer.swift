import Foundation
import VariableKit
import ATPathSpec

public struct AnalyzerDefinition {
    public let scope: VariableScope
    public let pathSpec: ATPathSpec
}

public class Analyzer {

    public let project: Project
    public let definition: AnalyzerDefinition
    public let scope: VariableScope
    public let evidenceSource: EvidenceSource
    public var pathSpec: ATPathSpec

    public init(project: Project, definition: AnalyzerDefinition) {
        self.project = project
        self.definition = definition
        self.scope = definition.scope
        self.pathSpec = definition.pathSpec  // TODO: resolve references in the definition
        evidenceSource = EvidenceSource(name: "Analyzer X")  // TODO: use a meaningful name
    }

}

public protocol AnalyzerHost {

//    let variableSet: VariableSet

}
