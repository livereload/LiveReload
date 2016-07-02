//
//  ProjectList.swift
//  LRProjectKit
//
//  Created by Andrey Tarantsov on 2016-06-11.
//  Copyright © 2016 Andrey Tarantsov. All rights reserved.
//

import Foundation

public class ProjectList {

    public private(set) var all: [Project] = []

    public func add(url: NSURL) {
        let project = Project(rootURL: url)
        all.append(project)
    }

}
