import Foundation
import Security

func sendSecureMessageToAppOwner(type: String, values: [String: AnyObject]) {
    let data = NSJSONSerialization.dataWithJSONObject(values, options: nil, error: nil)

    // TODO: use https://github.com/bigsan/RSAESCryptor
}