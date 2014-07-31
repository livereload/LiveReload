import Foundation

extension String {

    var argumentsArrayUsingBourneQuotingStyle: [String] {
    let s = self as NSString
        return s.argumentsArrayUsingBourneQuotingStyle() as [String]
    }

}

func quotedArgumentStringUsingBourneQuotingStyle(arguments: [String]) -> String {
    return (arguments as NSArray).quotedArgumentStringUsingBourneQuotingStyle()
}
