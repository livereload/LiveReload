import Foundation
import VariableKit
import ATPathSpec

public final class TagEvidenceTree: Printable {
    
    var filesToEvidence = [ProjectFile: [TagEvidence]]()
    var tagsToFiles = [Tag: Set<ProjectFile>]()
    
    public func replaceEvidence(#file: ProjectFile, newEvidence: [TagEvidence]) {
        deleteEvidence(file: file)
        filesToEvidence[file] = newEvidence
        for claim in newEvidence {
            if tagsToFiles[claim.tag] == nil {
                tagsToFiles[claim.tag] = Set<ProjectFile>()
            }
            tagsToFiles[claim.tag]?.insert(file)
        }
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
    
    public func findCoveringFoldersForTag(tag: Tag) -> [String] {
        println("findCoveringFoldersForTag(\(tag.name)):")
        var initialFolders: Set<String> = []
        for file in tagsToFiles[tag] ?? [] {
            initialFolders.insert(file.relativePath.stringByDeletingLastPathComponent)
        }
        println("  initialFolders = \(initialFolders)")
        
        var nextFolders: Set<String> = initialFolders
        var folderChildren: [String: Set<String>] = [:]
        while !nextFolders.isEmpty {
            let thisFolders = nextFolders
            nextFolders = []
            
            for folder in thisFolders {
                if folder != "" {
                    println("  visiting \(folder)")
                    let parent = folder.stringByDeletingLastPathComponent
                    if folderChildren[parent] == nil {
                        folderChildren[parent] = [folder]
                        nextFolders.insert(parent)
                    } else {
                        folderChildren[parent]!.insert(folder)
                    }
                }
            }
        }

        var junctions: [String] = []
        println("  collecting junctions")
        _collectJunctionPoints("", folderChildren: folderChildren, initialFolders: initialFolders, junctions: &junctions)
        println("  result = \(junctions)")
        return junctions
    }
    
    private func _collectJunctionPoints(folder: String, folderChildren: [String: Set<String>], initialFolders: Set<String>, inout junctions: [String]) {
        if initialFolders.contains(folder) {
            println("    folder with leaf files \(folder)")
            junctions.append(folder)
            // don't descend into children
        } else {
            let children = folderChildren[folder] ?? []
            if folder != "" && children.count >= 2 {
                println("    non-root junction folder \(folder)")
                junctions.append(folder)
                // don't descend into children for now, although it would return useful alternative folders
            } else {
                for child in children {
                    _collectJunctionPoints(child, folderChildren: folderChildren, initialFolders: initialFolders, junctions: &junctions)
                }
            }
        }
    }
    
}
