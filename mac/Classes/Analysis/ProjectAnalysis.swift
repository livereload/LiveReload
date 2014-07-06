import Foundation

class ProjectAnalysis: NSObject {

    let actionSet: ActionSet

    let classifier: FileClassifier

    init(actionSet: ActionSet) {
        self.actionSet = actionSet

        classifier = FileClassifier()
    }

    func updateResultsAfterModification(file: LRProjectFile) {
        let cluster = classifier.clusterMatchingFile(file)
//        for group in groups {
//            // TODO: rerun analyzers!
//        }
    }

    func updateResultsAfterDeletion(file: LRProjectFile) {

    }

}
