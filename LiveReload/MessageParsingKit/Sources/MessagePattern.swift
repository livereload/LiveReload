import Foundation

private let escapeSymbol = "\u{241B}"

private let fieldRegexp = try! NSRegularExpression(pattern: "\\(\\( ([\\w-]+) (?: : (.*?) )? \\)\\)", options: [.AllowCommentsAndWhitespace, .DotMatchesLineSeparators])

public class MessagePattern {
    
    public static let escapeMatchingString = "<ESC>"
    
    public let patternString: String

    internal let processedPatternString: String
    
    private let regexp: NSRegularExpression
    
    private let isMatchingEscapes: Bool
    
    private let groups: [MessageField: Int]
    
    public init(_ patternString: String, messageOverridePattern: String? = nil) throws {
        self.patternString = patternString
        
        isMatchingEscapes = patternString.containsString(MessagePattern.escapeMatchingString)
        let escapeNormalizedPatternString = (isMatchingEscapes ? patternString.stringByReplacingOccurrencesOfString(MessagePattern.escapeMatchingString, withString: escapeSymbol) : patternString)
        
        var group = 1
        var groups: [MessageField: Int] = [:]
        
        let processedPattern = fieldRegexp.replace(in: escapeNormalizedPatternString) { (groupStrings, _, _) -> String in
            let name = groupStrings[1]!

            let defaultRegexp: String
            if let field = MessageField.from(name: name) {
                groups[field] = group
                defaultRegexp = field.defaultRegexp
            } else {
                // TODO: report invalid field
                defaultRegexp = ".*"
            }
            group += 1

            return "(" + defaultRegexp + ")"
        }
        self.processedPatternString = processedPattern
        
        self.groups = groups
        
        self.regexp = try NSRegularExpression(pattern: processedPattern, options: [])
    }
    
    public func parse(text: String) -> (String, [Message]) {
        let normalizedText: String
        if isMatchingEscapes {
            normalizedText = text.stringByReplacingOccurrencesOfString(MessagePattern.escapeMatchingString, withString: escapeSymbol)
        } else {
            normalizedText = text.stringByReplacingOccurrencesOfString(MessagePattern.escapeMatchingString, withString: "")
        }
        
        var messages: [Message] = []
        
        let remainder = regexp.replace(in: normalizedText) { (groupStrings, _, _) -> String in
            var fieldValues: [MessageField: String] = [:]
            for (field, idx) in groups {
                if let s = groupStrings[idx] {
                    fieldValues[field] = s
                }
            }
            messages.append(Message(fieldValues: fieldValues))
            
            return ""
        }
        
        return (remainder, messages)
    }
    
}

private extension NSRegularExpression {
    
    func replace(in text: String, options: NSMatchingOptions = [], @noescape escape: (String) -> String = identityEscape, @noescape using block: ([String?], NSTextCheckingResult, NSMatchingFlags) -> String) -> String {
        var resultingString: String = ""
        var start = 0
        let bridged = text as NSString

        enumerateMatchesInString(text, options: options, range: NSMakeRange(0, bridged.length)) { (result, flags: NSMatchingFlags, _) in
            if let result = result {
                var groups: [String?] = []
                for i in 0 ..< result.numberOfRanges {
                    let r = result.rangeAtIndex(i)
                    if r.location == NSNotFound {
                        groups.append(nil)
                    } else {
                        let s = bridged.substringWithRange(r)
                        groups.append(s)
                    }
                }
                
                let matchRange = result.rangeAtIndex(0)
                let prefixRange = NSMakeRange(start, matchRange.location - start)
                resultingString.appendContentsOf(escape(bridged.substringWithRange(prefixRange)))
                start = matchRange.location + matchRange.length
                
                let replacement = block(groups, result, flags)
                resultingString.appendContentsOf(replacement)
            }
        }

        let finalRange = NSMakeRange(start, bridged.length - start)
        resultingString.appendContentsOf(escape(bridged.substringWithRange(finalRange)))

        return resultingString
    }
    
}

private func identityEscape(v: String) -> String {
    return v
}
