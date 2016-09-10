import Foundation

public extension NSJSONSerialization {

    public class func JSONObjectWithContentsOfURL(url: NSURL, options: NSJSONReadingOptions = []) throws -> AnyObject {
        let data = try NSData(contentsOfURL: url, options: [])
        return try NSJSONSerialization.JSONObjectWithData(data, options: options)
    }

}

public extension NSURL {

    public func checkIsAccessibleDirectory() -> Bool {
        let values = (try? self.resourceValuesForKeys([NSURLIsDirectoryKey])) ?? [:]
        return (values[NSURLIsDirectoryKey] as? Bool) ?? false
    }

}
