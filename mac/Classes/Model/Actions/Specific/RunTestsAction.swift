
import Foundation

// the name is referenced in plugin manifest
@objc(RunTestsAction)
class RunTestsAction : Action {

    override var label: String {
        return type.name
    }

    override func invokeWithModifiedFiles(files: AnyObject[]!, result: LROperationResult!, completionHandler: dispatch_block_t!) {
        if !effectiveVersion {
            result.completedWithInvocationError(missingEffectiveVersionError)
            completionHandler()
            return
        }

        let run = LRTRRun()
        let parser = LRTRTestAnythingProtocolParser()
        parser.delegate = run

        let step = ScriptInvocationStep()
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

        NSLog("%@: %@", label, project.rootURL.path)
        step.invoke()
    }

    override func targetForModifiedFiles(files: AnyObject[]!) -> LRTarget! {
        if inputPathSpecMatchesFiles(files) {
            return LRProjectTarget(action: self, modifiedFiles: files as LRProjectFile[])
        } else {
            return nil
        }
    }
    
}
