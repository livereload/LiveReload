import Foundation

private let escapeSymbol = "\u{241B}"

private let fieldRegexp = try! NSRegularExpression(pattern: "\\(\\( ([\\w-]+) (?: : (.*?) )? \\)\\)", options: [.AllowCommentsAndWhitespace, .DotMatchesLineSeparators])

private let ansiEscapeRegexp: NSRegularExpression = {
    // two-byte sequence: ESC <trailer>, where <trailer> is ASCII 64 to 95 (@ to _), except for [
    let twoByte = "\u{1b} [@A-Z\\\\\\]^_]"
    
    // multi-byte sequence that starts with CSI, Control Sequence Introducer
    
    // two-character CSI -- ESC [
    let twoCharCSI = "\u{1b} \\["
    // single-character CSI (less often used, but valid)
    let singleCharCSI = "\u{9b}"
    let csi = "(?: \(twoCharCSI) | \(singleCharCSI) )"
    
    // multi-byte sequence terminator, ASCII 64 to 126 (@ to ~)
    let terminator = "[@-~]"
    
    // multi-byte sequence that starts with CSI, followed by some arguments, followed by terminator
    let multiByte = "\(csi) .*? \(terminator)"
    
    let pattern = "(?: \(twoByte) | \(multiByte) )+"
    
    return try! NSRegularExpression(pattern: pattern, options: [.AllowCommentsAndWhitespace])
}()


public typealias MessageParsingResult = (remainder: String, messages: [Message])

public class MessagePattern {
    
    public static let escapeMatchingString = "<ESC>"
    
    public let patternString: String

    public let severity: MessageSeverity

    private let messageOverride: String?

    internal let processedPatternString: String
    
    private let regexp: NSRegularExpression
    
    private let isMatchingEscapes: Bool
    
    private let groups: [MessageField: Int]
    
    public init(_ patternString: String, severity: MessageSeverity, messageOverride: String? = nil) throws {
        self.patternString = patternString
        self.severity = severity
        self.messageOverride = messageOverride
        
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
                defaultRegexp = ".*?"
            }
            group += 1

            let customRegexp = groupStrings[2] ?? "***"
            let regexp = customRegexp.stringByReplacingOccurrencesOfString("***", withString: defaultRegexp)

            return "(" + regexp + ")"
        }
        self.processedPatternString = processedPattern
        
        self.groups = groups
        
        self.regexp = try NSRegularExpression(pattern: processedPattern, options: [])
    }
    
    public func parse(text: String) -> MessageParsingResult {
        let normalizedText: String
        if isMatchingEscapes {
            normalizedText = normalize(ansiEscapeRegexp.replace(in: text, withTemplate: escapeSymbol))
        } else {
            normalizedText = normalize(ansiEscapeRegexp.replace(in: text, withTemplate: ""))
        }
        
        var messages: [Message] = []
        
        let remainder = regexp.replace(in: normalizedText) { (groupStrings, _, _) -> String in
            var fieldValues: [MessageField: String] = [:]
            for (field, idx) in groups {
                if let s = groupStrings[idx] {
                    fieldValues[field] = s
                }
            }
            
            var message = Message(severity: severity, fieldValues: fieldValues)
            if let messageOverride = messageOverride {
                let originalText = message.text ?? ""
                message.text = messageOverride.stringByReplacingOccurrencesOfString("***", withString: originalText)
            }
            
            messages.append(message)
            
            return ""
        }.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())

        return (remainder, messages)
    }
    
    public static func parse(text: String, using patterns: [MessagePattern]) -> MessageParsingResult {
        var text = text.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
        
        var messages: [Message] = []
        
        for pattern in patterns {
            if text.isEmpty {
                break
            }
            
            let (remainder, messagesThisTime) = pattern.parse(text)
            messages.appendContentsOf(messagesThisTime)
            text = remainder
        }
        
        return (text, messages)
    }
    
}

private extension NSRegularExpression {

    func replace(in text: String, withTemplate template: String) -> String {
        let bridged = text as NSString
        return stringByReplacingMatchesInString(text, options: [], range: NSMakeRange(0, bridged.length), withTemplate: template)
    }
    
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

private func normalize(s: String) -> String {
    return s.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()) + "\n"
}
