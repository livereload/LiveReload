//
//  PathProcessing.swift
//  LRActionKit
//
//  Created by Andrey Tarantsov on 2015-10-09.
//  Copyright © 2015 Andrey Tarantsov. All rights reserved.
//

import Foundation
import ATPathSpec

private let STAR_CHARSET = NSCharacterSet(charactersInString: "*")

public enum OutputMaskParseError: ErrorType {
    case MissingStar
    case MultipleStars
}

public struct OutputMask {

    public let prefix: String
    public let suffix: String

    public init(string: String) throws {
        let components = string.componentsSeparatedByCharactersInSet(STAR_CHARSET)
        guard components.count == 2 else {
            if components.count < 2 {
                throw OutputMaskParseError.MissingStar
            } else {
                throw OutputMaskParseError.MultipleStars
            }
        }
        prefix = components[0]
        suffix = components[1]
    }

    public func replaceStarWith(pathString: String) -> String {
        if !suffix.isEmpty && pathString.hasSuffix(suffix) {
            return prefix + pathString
        } else {
            return prefix + pathString + suffix
        }
    }

    public func deriveOutputPathFromSourcePath(sourcePath: RelPath, sourcePathSpec: ATPathSpec) -> RelPath? {
        guard let details = sourcePathSpec.includesWithDetails(sourcePath) else {
            return nil
        }
        guard let suffix = details.matchedSuffix else {
            return nil
        }
        let sourceBasePath = sourcePath.replaceSuffix(suffix, "").0
        return RelPath(replaceStarWith(sourceBasePath.pathString), isDirectory: sourcePath.isDirectory)
    }

}
