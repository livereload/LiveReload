import Foundation
import VariableKit
import ATPathSpec

public class Tagger {

    public func computeTags(#file: ProjectFile) -> [TagEvidence] {
        return []
    }

}

public class FileSpecTagger : Tagger {

    private let spec: ATPathSpec
    private let tag: Tag

    public init(spec: ATPathSpec, tag: Tag) {
        self.spec = spec
        self.tag = tag
    }

    public override func computeTags(#file: ProjectFile) -> [TagEvidence] {
        if spec.matchesPath(file.relativePath, type: .File) {
            return [TagEvidence(tag: tag)]
        } else {
            return []
        }
    }

}
