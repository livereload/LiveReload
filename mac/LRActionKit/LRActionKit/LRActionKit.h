#import <Cocoa/Cocoa.h>

//! Project version number for LRActionKit.
FOUNDATION_EXPORT double LRActionKitVersionNumber;

//! Project version string for LRActionKit.
FOUNDATION_EXPORT const unsigned char LRActionKitVersionString[];

// basics
#import <LRActionKit/ActionKitGlobals.h>
#import <LRActionKit/ActionKitSingleton.h>
#import <LRActionKit/LRManifestBasedObject.h>
#import <LRActionKit/LRManifestErrorSink.h>
#import <LRActionKit/LRChildErrorSink.h>

// action
#import <LRActionKit/LRContextAction.h>
#import <LRActionKit/LRActionManifest.h>
#import <LRActionKit/LRAssetPackageConfiguration.h>

#import <LRActionKit/LRManifestLayer.h>

// rule
#import <LRActionKit/ScriptInvocationStep.h>

// result
#import <LRActionKit/LROperationResult.h>

// inputs
#import <LRActionKit/FilterOption.h>
#import <LRActionKit/LRVersionSpec.h>
#import <LRActionKit/LRVersionTag.h>

// testing
#import <LRActionKit/LRTRGlobals.h>
#import <LRActionKit/LRTRProtocolParser.h>
#import <LRActionKit/LRTRRun.h>
#import <LRActionKit/LRTRTest.h>
#import <LRActionKit/LRTRTestAnythingProtocolParser.h>

// analysis
#import <LRActionKit/ImportGraph.h>
#import <LRActionKit/LRVersionSpec.h>
#import <LRActionKit/LRVersionTag.h>

// utilities
#import <LRActionKit/LRPathProcessing.h>
#import <LRActionKit/UserScript.h>
