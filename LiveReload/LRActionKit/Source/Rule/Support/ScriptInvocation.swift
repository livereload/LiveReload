import Foundation
import PackageManagerKit
import ExpressiveCocoa

public class ScriptInvocationRule : Rule {

    public override func invokeWithModifiedFiles(files: [ProjectFile], result: LROperationResult, completionHandler: dispatch_block_t) {
    }

    public override func compileFile(file: ProjectFile, result: LROperationResult, completionHandler: dispatch_block_t) {
        if effectiveVersion == nil {
            result.completedWithInvocationError(missingEffectiveVersionError)
            completionHandler()
            return
        }

        let step = ScriptInvocationStep(project: project)
        step.result = result
        configureStep(step, forFile: file)

        step.completionHandler = { step in
            self.didCompleteCompilationStep(step, forFile: file)
            completionHandler()
        }

        NSLog("%@: %@", self.label, file.absolutePath)
        step.invoke()
    }

    public func configureStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
        configureStep(step)
    }

    public func didCompleteCompilationStep(step: ScriptInvocationStep, forFile file: ProjectFile) {
    }

}

public class ScriptInvocationStep: NSObject {
    
    private var referenceCycle: AnyObject?

    private var substitutions: [String: [String]] = [:]

    private var files: [String: ProjectFile] = [:]

    private var environment = NSProcessInfo.processInfo().environment

    public let project: ProjectContext
    public var commandLine: [String] = []
    public var result: LROperationResult?
    public var rubyInstance: RuntimeInstance?

    public private(set) var finished: Bool = false
    public private(set) var error: NSError?

    public var completionHandler: ((step: ScriptInvocationStep) -> Void)?
    public var outputLineBlock: (@convention(block) (line: String) -> Void)?

    public init(project: ProjectContext) {
        self.project = project
        super.init()

        addStringValue("node", NSBundle.mainBundle().pathForResource("LiveReloadNodejs", ofType: nil)!)
    }

    public func addStringValue(key: String, _ value: String) {
        substitutions[key] = [value]
    }

    public func addStringMultiValue(key: String, _ mvalue: [String]) {
        substitutions[key] = mvalue
    }

    public func addFileValue(key: String, _ file: ProjectFile) {
        files[key] = file

        addStringValue("\(key)_file", file.path.lastComponent ?? "")
        addStringValue("\(key)_path", file.absoluteURL.path!)
        addStringValue("\(key)_dir", file.absoluteURL.URLByDeletingLastPathComponent!.path!)
        addStringValue("\(key)_rel_path", file.path.pathString)
    }

    public func fileForKey(key: String) -> ProjectFile? {
        return files[key]
    }

    public func invoke() {
        let pm = ActionKitSingleton.sharedActionKit.packageManager
        let bundledContainers = pm.packageTypeNamed("gem")!.containers.filter { $0.containerType == .Bundled }

        let rubyInstance = project.rubyInstanceForBuilding

        let env = NSMutableDictionary(dictionary: environment)
        addStringMultiValue("ruby", rubyInstance.launchArgumentsWithAdditionalRuntimeContainers(bundledContainers, environment: env))
        environment = env as NSDictionary as! [String: String]
        
        let cmdline = substituteArray(commandLine, substitutions)

        //    //    NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
        //    //    [[NSFileManager defaultManager] changeCurrentDirectoryPath:projectPath];

        ////    console_printf("Exec: %s", str_collapse_paths([[cmdline quotedArgumentStringUsingBourneQuotingStyle] UTF8String], [_project.path UTF8String]));
        //    // TODO XXX: collapse project path
        NSLog("Exec: %@", cmdline)

        let command = NSURL.fileURLWithPath(cmdline[0])
        let args = Array(cmdline[1..<cmdline.count])
        
        var options: [String: AnyObject] = [:]
        options[ATCurrentDirectoryPathKey] = project.rootURL.path
        options[ATEnvironmentVariablesKey] = environment
        if let outputLineBlock = outputLineBlock {
            // <#todo#> TODO check if this cast is valid
            options[ATStandardOutputLineBlockKey] = outputLineBlock as! AnyObject
        }
        
        referenceCycle = self
        ATLaunchUnixTaskAndCaptureOutput(command, args, [.IgnoreSandbox, .MergeStdoutAndStderr], options) { (outputText, stderrText, error) in
            self.error = error
            
            let result = self.result!
            
            result.addRawOutput(outputText) {
                result.completedWithInvocationError(error)
                self.finished = true
                if let completionHandler = self.completionHandler {
                    self.referenceCycle = nil
                    completionHandler(step: self)
                }
            }
        }
    }

}

private func substituteArray(items: [String], _ substitutions: [String: [String]]) -> [String] {
    return items.flatMap { substituteItem($0, substitutions) }
}

private func substituteItem(item: String, _ substitutions: [String: [String]]) -> [String] {
    if item.hasPrefix("$(") && item.hasSuffix(")") {
        let p = item.rangeOfString("$(")!
        let s = item.rangeOfString(")", options: .BackwardsSearch, range: nil, locale: nil)!
        let key = item.substringWithRange(p.endIndex ..< s.startIndex)
        if let values = substitutions[key] {
            return values
        } else {
            return [item]
        }
    } else {
        var result = item
        for (key, value) in substitutions where value.count == 1 {
            result = result.stringByReplacingOccurrencesOfString("$(" + key + ")", withString: value[0])
        }
        return [result]
    }
}
