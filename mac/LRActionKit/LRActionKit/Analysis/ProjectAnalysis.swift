import Foundation
import VariableKit
import ATPathSpec

public class ProjectAnalysis: NSObject, AnalyzerHost {

    public let actionSet: ActionSet

    // let classifier: FileClassifier

    public let analyzers: [Analyzer]

//    let variableSet: VariableSet

    public init(actionSet: ActionSet) {
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

    public func updateResultsAfterModification(file: ProjectFile) {
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

    public func updateResultsAfterDeletion(file: ProjectFile) {

    }

    public func lookupVariable(name: String) -> Variable {
        abort()
    }

}
