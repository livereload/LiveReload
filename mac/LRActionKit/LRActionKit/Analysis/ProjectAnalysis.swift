import Foundation
import SwiftyFoundation
import VariableKit
import ATPathSpec

public class ProjectAnalysis: NSObject {

    public let actionSet: ActionSet

    public var taggers: [Tagger] = []

    public let tree = TagEvidenceTree()

    public init(actionSet: ActionSet) {
        self.actionSet = actionSet
        super.init()
        
        taggers = flatten(actionSet.actions.map { $0.taggers })
    }

    public func updateResultsAfterModification(file: ProjectFile) {
        var evidence: [TagEvidence] = []
        for tagger in taggers {
            evidence.extend(tagger.computeTags(file: file))
        }
        tree.replaceEvidence(file: file, newEvidence: evidence)
    }

    public func updateResultsAfterDeletion(file: ProjectFile) {
        tree.deleteEvidence(file: file)
    }
    
    public func analysisDidFinish() {
        println(tree.description)
    }
}
