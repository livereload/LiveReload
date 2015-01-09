import Foundation
import Security
import AFNetworking
import SwiftyFoundation

public struct BetaSignupData {

    let name: String
    let email: String
    let about: String

    public init(name: String, email: String, about: String) {
        self.name = name
        self.email = email
        self.about = about
    }
    
}

@objc
public class MarketingCommunication : NSObject {

    public class var instance: MarketingCommunication {
        return MarketingCommunication()
    }

    private let client: AFHTTPSessionManager

    private override init() {
        var baseURL = "http://api.livereload.com"
        if let baseURLOverride: String = NSProcessInfo.processInfo().environment["LRMarketingServerURLOverride"]~~~ {
            if baseURLOverride.rangeOfString("://", options: nil, range: nil, locale: nil) == nil {
                baseURL = "http://\(baseURLOverride)"
            } else {
                baseURL = baseURLOverride
            }
        }
        client = AFHTTPSessionManager(baseURL: NSURL(string: baseURL)!.URLByAppendingPathComponent("api/v1"))
        super.init()
    }

    public var betaUserInfoSent: Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("BetaUser.sent")
    }

    public func loadPreviousBetaSignupData() -> BetaSignupData {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        return BetaSignupData(
            name: defaults.stringForKey("BetaUser.name") ?? "",
            email: defaults.stringForKey("BetaUser.email") ?? "",
            about: defaults.stringForKey("BetaUser.about") ?? "")
    }

    public func sendBetaSignup(data: BetaSignupData, callback: (NSError?) -> Void) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(data.name, forKey: "BetaUser.name")
        defaults.setObject(data.email, forKey: "BetaUser.email")
        defaults.setObject(data.about, forKey: "BetaUser.about")
        defaults.synchronize()

        let parameters = [
            "name": data.name,
            "email": data.email,
            "about": data.about,
            "appPlatform": "mac",
            "appVersion": NSBundle.mainBundle().infoDictionary![kCFBundleVersionKey]!
        ]
        client.POST("beta-signup/", parameters: parameters as NSDictionary, success: { (task, result) -> Void in
            NSLog("result = %@", result as NSObject)
            let dictionary = (result as? [String: AnyObject]) ?? [:]
            let ok: String = dictionary["ok"] ~|||~ ""
            if ok == "ok" {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "BetaUser.sent")
                NSUserDefaults.standardUserDefaults().synchronize()
                callback(nil)
            } else {
                callback(NSError(domain: "com.livereload.LRMarketingKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
        }, failure: { (task, error) -> Void in
            NSLog("failed: %@", error)
            callback(error)
        })
    }

}

//public func sendSecureMessageToAppOwner(type: String, values: [String: AnyObject]) {
//    var payload = values
//    payload["app-version"] = NSBundle.mainBundle().infoDictionary[kCFBundleVersionKey]
//
//    let data = NSJSONSerialization.dataWithJSONObject(payload, options: nil, error: nil)
//
//    let cryptor = RSAESCryptor()
//    cryptor.loadPublicKey(NSBundle(forClass: MarketingKitDummyClass.self).pathForResource("LiveReload-messaging.der", ofType: nil))
//    let encrypted = cryptor.encryptData(data)
//
////    let connection = NSURLConnection(request: <#NSURLRequest!#>, delegate: <#AnyObject!#>)
//    println("Encrypted message \(type): \(encrypted)")
//}

