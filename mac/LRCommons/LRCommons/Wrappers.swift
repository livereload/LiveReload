import Foundation

public extension NSString {

    func stringBySubstitutingValuesFromDictionary(values: [String: AnyObject]) -> String {
        return (self as NSString).p2_stringBySubstitutingValuesFromDictionary(values)
    }

    func argumentsArrayUsingBourneQuotingStyle() -> [String] {
        return (self as NSString).p2_argumentsArrayUsingBourneQuotingStyle() as! [String]
    }

}

public func quotedArgumentStringUsingBourneQuotingStyle(arguments: [String]) -> String {
    return (arguments as NSArray).p2_quotedArgumentStringUsingBourneQuotingStyle()
}

public func arrayBySubstitutingValuesFromDictionary(array: [String], values: [String: String]) -> [String] {
    return (array as NSArray).p2_arrayBySubstitutingValuesFromDictionary(values) as! [String]
}
