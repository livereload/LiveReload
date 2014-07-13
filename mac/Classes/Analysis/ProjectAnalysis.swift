import Foundation

class ProjectAnalysis: NSObject, AnalyzerHost {

    let actionSet: ActionSet

    // let classifier: FileClassifier

    var analyzers = [Analyzer]()

    init(actionSet: ActionSet) {
        self.actionSet = actionSet
        super.init()

        //classifier = FileClassifier()

        analyzers.append(ImportFragmentAnalyzer(project: actionSet.project, host: self, definition: AnalyzerDefinition(scope: .File, pathSpec: ATPathSpec(string: "*.less", syntaxOptions:.FlavorExtended))))
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
