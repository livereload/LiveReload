import Foundation
import SwiftyFoundation
import VariableKit
import ATPathSpec

public class ProjectAnalysis: NSObject {

    public let actionSet: ActionSet
    public let rulebook: Rulebook

    public var taggers: [Tagger] = []
    public var derivers: [Deriver] = []

    public let tree = TagEvidenceTree()

    public init(actionSet: ActionSet, rulebook: Rulebook) {
        self.actionSet = actionSet
        self.rulebook = rulebook
        super.init()
        
        taggers = flatten(actionSet.actions.map { $0.taggers })
        derivers = flatten(actionSet.actions.map { $0.derivers })
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
        updateDerivation()
        println(tree.description)
    }
    
    private func updateDerivation() {
        var derivedRules: [Rule] = []
        for deriver in derivers {
            derivedRules.extend(deriver.deriveRules(fromTagTree: tree, forActionSet: actionSet))
        }
        println("Derived rules:\n\(derivedRules)")
        rulebook.addDerivedRulesIfNecessary(derivedRules)
    }

}
