import Foundation
import ATPathSpec

public class FileClassifier {

    private var groups: [FileGroup] = []

    public func addGroups(newGroups: [FileGroup]) {
        groups.appendContentsOf(newGroups)
    }

    public func clusterMatchingFile(file: ProjectFile) -> FileCluster {
        // TODO: more efficient implementation
        return FileCluster(groups: groups.filter { $0.matchesFile(file) })
    }

}

public class FileGroup {

    public let pathSpec: ATPathSpec

    public init(pathSpec: ATPathSpec) {
        self.pathSpec = pathSpec
    }

    public func matchesFile(file: ProjectFile) -> Bool {
        return pathSpec.matchesPath(file.relativePath, type:ATPathSpecEntryType.File)
    }

}

// cluster is a unique collection of groups within a classifier
public class FileCluster {

    public let groups: [FileGroup]

    public init(groups: [FileGroup]) {
        self.groups = groups
    }

}
