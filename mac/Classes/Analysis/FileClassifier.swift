import Foundation

class FileClassifier {

    /*private*/ var groups: [FileGroup] = []

    func addGroups(newGroups: [FileGroup]) {
        groups.extend(newGroups)
    }

    func clusterMatchingFile(file: LRProjectFile) -> FileCluster {
        // TODO: more efficient implementation
        return FileCluster(groups: groups.filter { $0.matchesFile(file) })
    }

}

class FileGroup {

    let pathSpec: ATPathSpec

    init(pathSpec: ATPathSpec) {
        self.pathSpec = pathSpec
    }

    func matchesFile(file: LRProjectFile) -> Bool {
        return pathSpec.matchesPath(file.relativePath, type:ATPathSpecEntryType.File)
    }

}

// cluster is a unique collection of groups within a classifier
class FileCluster {

    let groups: [FileGroup]

    init(groups: [FileGroup]) {
        self.groups = groups
    }

}
