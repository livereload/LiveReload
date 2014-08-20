//
//  AppDelegate.swift
//  LiveReload UI Experiments
//
//  Created by Andrey Tarantsov on 14.08.2014.
//  Copyright (c) 2014 LiveReload. All rights reserved.
//

import Cocoa
import LRMarketingKit
import LRActionsPresentationKit
import YAML

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    var window: NSWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
//        MarketingCommunication.instance.sendBetaSignup(BetaSignupData(name: "Andrey", email: "andrey+test2@tarantsov.com", about: "Just me, ya know")) { error in
//            println("done, error = \(error)")
//        }

//        window = EmailSignupWindow.create()

        let yamlString = NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("narratives.yml", withExtension: nil), encoding: NSUTF8StringEncoding, error: nil)
        if let yaml: AnyObject = YAMLSerialization.objectWithYAMLString(yamlString, options: .StringScalars, error: nil) {
            let wc = ExperimentalActionsWindowController(windowNibName: "ExperimentalActionsWindowController")
            wc.narratives = yaml as [String: AnyObject]
            window = wc
        } else {
            fatalError("Failed to parse YAML")
        }

        window.showWindow(self)
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }


}

