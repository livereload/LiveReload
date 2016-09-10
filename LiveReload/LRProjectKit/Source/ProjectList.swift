//
//  ProjectList.swift
//  LRProjectKit
//
//  Created by Andrey Tarantsov on 2016-06-11.
//  Copyright © 2016 Andrey Tarantsov. All rights reserved.
//

import Foundation
import Uniflow

public struct ProjectList {
    
    public static let tag = Tag("ProjectList")
    
    public var projects: [Project] = []
    
    public init() {
    }
    
    public func isDifferent(from older: ProjectList) -> Bool {
        return self.projects != older.projects
    }
    
}

public class ProjectListController: Source {
    
    public let bus: Bus

    public private(set) var value = ProjectList()
    
    public init(bus: Bus) {
        self.bus = bus
        bus.add(self)
    }
    
    public func add(url: NSURL, reason: ChangeReason, via bus: Bus) {
        bus.perform(AddChange(controller: self, url: url), reason: reason)
    }
    
    private struct AddChange: Change {
        
        private let controller: ProjectListController
        private let url: NSURL

        var affectedTags: [Tag] {
            return [ProjectList.tag]
        }
        
        func perform() {
            let project = Project(rootURL: url)
            controller.value.projects.append(project)
        }
        
    }
    
    
    // Source
    
    public let dependentTags: [Tag] = []
    public let affectedTags: [Tag] = [ProjectList.tag]
    
    public func update(session: UpdateSession) {
        // TODO: load the list from disk
    }

}
