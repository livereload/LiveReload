//
//  AppDelegate.swift
//  LiveReload UI Experiments
//
//  Created by Andrey Tarantsov on 14.08.2014.
//  Copyright (c) 2014 LiveReload. All rights reserved.
//

import Cocoa
import LRMarketingKit

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    var window: NSWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
//        MarketingCommunication.instance.sendBetaSignup(BetaSignupData(name: "Andrey", email: "andrey+test2@tarantsov.com", about: "Just me, ya know")) { error in
//            println("done, error = \(error)")
//        }

        window = EmailSignupWindow.create()

//        window = ExperimentalActionsWindowController(windowNibName: "ExperimentalActionsWindowController")

        window.showWindow(self)
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }


}

