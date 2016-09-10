import Foundation
import PackageManagerKit

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
    public var outputLineBlock: ((line: String) -> Void)?

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

    func invoke() {
        let pm = ActionKitSingleton.sharedActionKit.packageManager
        let bundledContainers = pm.packageTypeNamed("gem")!.containers.filter { $0.containerType == .Bundled }

        let rubyInstance = project.rubyInstanceForBuilding

        let env = NSMutableDictionary(dictionary: environment)
        addStringMultiValue("ruby", rubyInstance.launchArgumentsWithAdditionalRuntimeContainers(bundledContainers, environment: env))
        environment = env as NSDictionary as! [String: String]
    }

    //- (void)invoke {
//    NSArray *bundledContainers = [[[ActionKitSingleton sharedActionKit].packageManager packageTypeNamed:@"gem"].containers filteredArrayUsingBlock:^BOOL(LRPackageContainer *container) {
//        return container.containerType == LRPackageContainerTypeBundled;
//    }];
//
//    RuntimeInstance *rubyInstance = _project.rubyInstanceForBuilding;
//    [self addValue:[rubyInstance launchArgumentsWithAdditionalRuntimeContainers:bundledContainers environment:_environment] forSubstitutionKey:];
//
//    NSArray *cmdline = [_commandLine p2_arrayBySubstitutingValuesFromDictionary:_substitutions];
//
//    //    NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
//    //    [[NSFileManager defaultManager] changeCurrentDirectoryPath:projectPath];
//
//    // TODO XXX
////    console_printf("Exec: %s", str_collapse_paths([[cmdline quotedArgumentStringUsingBourneQuotingStyle] UTF8String], [_project.path UTF8String]));
//    // TODO XXX: collapse project path
//    NSLog(@"Exec: %@", [cmdline p2_quotedArgumentStringUsingBourneQuotingStyle]);
//
//    NSString *command = cmdline[0];
//    NSArray *args = [cmdline subarrayWithRange:NSMakeRange(1, cmdline.count - 1)];
//    NSMutableDictionary *options = [@{ATCurrentDirectoryPathKey: _project.path, ATEnvironmentVariablesKey: _environment} mutableCopy];
//    if (_outputLineBlock) {
//        options[ATStandardOutputLineBlockKey] = _outputLineBlock;
//    }
//    ATLaunchUnixTaskAndCaptureOutput([NSURL fileURLWithPath:command], args, ATLaunchUnixTaskAndCaptureOutputOptionsIgnoreSandbox|ATLaunchUnixTaskAndCaptureOutputOptionsMergeStdoutAndStderr, options, ^(NSString *outputText, NSString *stderrText, NSError *error) {
//        _error = error;
//        P2DisableARCRetainCyclesWarning()
//        [_result addRawOutput:outputText withCompletionBlock:^{
//            [_result completedWithInvocationError:error];
//            self.finished = YES;
//            if (self.completionHandler)
//                self.completionHandler(self);
//        }];
//        P2ReenableWarning()
//    });
//}
//
//@end

}

//
//
//typedef void (^ScriptInvocationOutputLineBlock)(NSString *line);
