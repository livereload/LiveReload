import Foundation
import ExpressiveFoundation
import ExpressiveCollections
import PackageManagerKit
import Swift

public class LRContextAction: NSObject {

    public static let didChangeVersionsNotification = "LRContextActionDidChangeVersions"
    
    public let action: Action
    public let project: ProjectContext
    public let resolutionContext: LRPackageResolutionContext

    public private(set) var versions: [LRActionVersion] = []
    public private(set) var versionSpecs: [LRVersionSpec] = []

    public init(action: Action, project: ProjectContext, resolutionContext: LRPackageResolutionContext) {
        self.action = action
        self.project = project
        self.resolutionContext = resolutionContext
        super.init()

        updateCoalescence.monitorBlock = { (running) in 
            project.setAnalysisInProgress(running, forTask: self)
        }

        o.on(LRPackageContainerDidChangePackageListNotification, self, LRContextAction.updateAvailableVersions)
        updateAvailableVersions()
    }

    public override var description: String {
        return "\(action) #ver=\(versions.count) proj=\(project)"
    }

    public func newInstance(memento memento: [String: AnyObject]) -> Rule {
        return action.newRule(contextAction: self, memento: memento)
    }

    private func updateAvailableVersions() {
        updateCoalescence.perform {
            self.versions = self._computeAvailableVersions()
            self.versionSpecs = self._computeAvailableVersionSpecs()
            self.postNotification(LRContextAction.didChangeVersionsNotification)
        }
    }

    private func _computeAvailableVersions() -> [LRActionVersion] {
        if !action.valid {
            print("ContextAction(\(action.name)) has invalid manifest, so no versions")
            return []
        }

        let packageSets = action.packageConfigurations.map { self.resolutionContext.packageSetsMatchingPackageReferences($0.packageReferences) as! [LRPackageSet] }.flatten()

        let versions = packageSets.mapIf { packageSet -> LRActionVersion? in
            let layers = self.action.manifestLayers.filter { packageSet.matchesAllPackageReferencesInArray($0.packageReferences) }
            let manifest = LRActionManifest(layers: layers)
            if manifest.valid {
                return LRActionVersion(action: self.action, manifest: manifest, packageSet: packageSet)
            } else {
                print("ContextAction(\(self.action.name)) skipping version \(packageSet.primaryPackage) b/c of invalid manifest: \(manifest.errors)")
                return nil
            }
        }

        let sortedVersions = versions.sort { (a: LRActionVersion, b: LRActionVersion) -> Bool in
            return (a.primaryVersion.compare(b.primaryVersion) == .OrderedAscending)
        }

        return sortedVersions
    }

    private func _computeAvailableVersionSpecs() -> [LRVersionSpec] {
        var specs: [LRVersionSpec] = []
        var set = Set<LRVersionSpec>()

        for actionVersion in versions {
            let versionSpecs = [
                LRVersionSpec.stableVersionSpecWithMajorFromVersion(actionVersion.primaryVersion),
                LRVersionSpec(matchingMajorMinorFromVersion: actionVersion.primaryVersion),
                LRVersionSpec(matchingVersion: actionVersion.primaryVersion)
            ]
            for spec in versionSpecs {
                if !set.contains(spec) {
                    spec.changeLogSummary = actionVersion.manifest.changeLogSummary
                    set.insert(spec)
                    specs.append(spec)
                }
            }
        }
        
        if let primaryVersionSpace = action.primaryVersionSpace {
            specs.append(LRVersionSpec.stableVersionSpecMatchingAnyVersionInVersionSpace(primaryVersionSpace))
        }
        
        return specs
    }

    private let updateCoalescence = Coalescence()
    private var o = Observation()

}
