import Foundation

enum AnalyzerScope {
    case File
    case Project
}

struct AnalyzerDefinition {

    let scope: AnalyzerScope

    let pathSpec: ATPathSpec

}

class Analyzer {

    let project: Project
    let host: AnalyzerHost
    let definition: AnalyzerDefinition
    let scope: AnalyzerScope
    var pathSpec: ATPathSpec

    init(project: Project, host: AnalyzerHost, definition: AnalyzerDefinition) {
        self.project = project
        self.host = host
        self.definition = definition
        self.scope = definition.scope
        self.pathSpec = definition.pathSpec  // TODO: resolve references in the definition
    }

}

protocol AnalyzerHost {

    func lookupVariable(name: String) -> Variable

}
