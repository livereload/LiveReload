import Foundation
import VariableKit
import ATPathSpec

public final class TagEvidenceTree: Printable {
    
    var filesToEvidence = [ProjectFile: [TagEvidence]]()
    // var tagsToFiles = [Tag: Set<ProjectFile>]
    
    public func replaceEvidence(#file: ProjectFile, newEvidence: [TagEvidence]) {
        filesToEvidence[file] = newEvidence
    }
    
    public func deleteEvidence(#file: ProjectFile) {
        filesToEvidence[file] = nil
    }
    
    public var description: String  {
        var lines : [String] = []
        let sortedFiles = sorted(filesToEvidence.keys) { $0.relativePath < $1.relativePath }
        for file in sortedFiles {
            let evidence = filesToEvidence[file]!
            let evidenceString = join(", ", evidence.map { $0.description })
            let line = "\(file.relativePath) -> \(evidenceString)"
            lines.append(line)
        }
        return join("\n", lines);
    }
    
}
