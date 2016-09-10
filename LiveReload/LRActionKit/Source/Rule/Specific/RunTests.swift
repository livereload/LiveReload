import Foundation

public class RunTestsRule : Rule {

    public override func invokeWithModifiedFiles(files: [ProjectFile], result: LROperationResult, completionHandler: dispatch_block_t) {
        if effectiveVersion == nil {
            result.completedWithInvocationError(missingEffectiveVersionError)
            completionHandler()
            return
        }

        let run = LRTRRun()
        let parser = LRTRTestAnythingProtocolParser()
        parser.delegate = run

        let step = ScriptInvocationStep(project: project)
        step.result = result
        configureStep(step)

        step.completionHandler = { step in
            parser.finish()
            NSLog("Tests = %@", run.tests)
            completionHandler()
        }

        step.outputLineBlock = { line in
            NSLog("Testing output line: %@", line.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet()))
            parser.processLine(line)
        }

        NSLog("%@: %@", label, project.rootURL.path!)
        step.invoke()
    }

    public override func targetForModifiedFiles(files: [ProjectFile]) -> LRTarget? {
        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(rule: self, modifiedFiles: files as [ProjectFile])
        } else {
            return nil
        }
    }
    
}
