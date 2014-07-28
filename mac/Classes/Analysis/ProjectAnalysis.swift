import Foundation
import VariableKit
import LRActionKit

class ProjectAnalysis: NSObject, AnalyzerHost {

    let actionSet: ActionSet

    // let classifier: FileClassifier

    let analyzers: [Analyzer]

//    let variableSet: VariableSet

    init(actionSet: ActionSet) {
        self.actionSet = actionSet

        var analyzers = [Analyzer]()
        analyzers.append(ImportFragmentAnalyzer(project: actionSet.project, definition: AnalyzerDefinition(scope: .File, pathSpec: ATPathSpec(string: "*.less", syntaxOptions:.FlavorExtended))))

//        var variableDefinitions = [VariableDefinition]()
//        variableDefinitions.append(VariableDefinition(name: "compiler", scope: .File, foldingBehavior: .Folded))
//
//        let sources = analyzers.map { $0.evidenceSource }

        self.analyzers = analyzers
//        variableSet = VariableSet(variableDefinitions: variableDefinitions, sources: sources)

        super.init()

        //classifier = FileClassifier()

    }

    func updateResultsAfterModification(file: LRProjectFile) {
        for analyzer in analyzers {
            if analyzer.pathSpec.matchesPath(file.relativePath, type: .File) {
                //<#qq#>
            }
        }
//        let cluster = classifier.clusterMatchingFile(file)
//        for group in groups {
//            // TODO: rerun analyzers!
//        }
    }

    func updateResultsAfterDeletion(file: LRProjectFile) {

    }

    func lookupVariable(name: String) -> Variable {
        abort()
    }

}
