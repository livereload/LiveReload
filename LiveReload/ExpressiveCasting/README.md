# ExpressiveCasting

<img alt="status beta" src="https://img.shields.io/badge/status-beta-yellowgreen.svg"></a>
<img alt="Swift 2.2" src="https://img.shields.io/badge/Swift-2.2-brightgreen.svg">
<img alt="Swift 3" src="https://img.shields.io/badge/Swift-3-brightgreen.svg">
<img alt="" src="https://img.shields.io/cocoapods/p/ExpressiveCasting.svg">
<img alt="" src="https://img.shields.io/cocoapods/v/ExpressiveCasting.svg">
<a href="https://github.com/Carthage/Carthage"><img alt="Carthage incompatible" src="https://img.shields.io/badge/Carthage-incompatible-red.svg"></a>
<a href="https://swift.org/package-manager/"><img alt="Swift Package Manager compatible" src="https://img.shields.io/badge/Swift_PM-compatible-brightgreen.svg"></a>

Swift µ-framework for writing concise and expressive code when processing untyped and potentially untrusted incoming data (JSON, User Defaults, command-line arguments and such).

Part of [ExpressiveSwift](https://github.com/ExpressiveSwift/ExpressiveSwift), a collection of µ-frameworks solving specific problems with straightforward, concise, readable and safe code.

**Beta status**: (1) is used in multiple production apps, (2) documentation effort is in progress, (3) may still undergo heavy or incompatible changes.

© 2016, Andrey Tarantsov. Distributed under the [MIT license](LICENSE).


## Usage

Provides two alternative interfaces:

1. A set of casting functions (`BoolValue`, `IntValue`, `DoubleValue`, `StringValue`, `NonEmptyStringValue`, `ArrayValue`, `JSONObjectValue`, `JSONObjectsArrayValue`), most taking `AnyObject?` as an argument and returning the given type or `nil`.

2. A fuzzy cast postfix operator, `~~~`, providing a terse syntax for the abovementioned functions.


### Aliases

The library defines two type aliases to make dealing with JSON data types easier:

* `typealias JSONObject = [String: AnyObject]`
* `typealias JSONArray = [AnyObject]`


### Simple value casts

* `BoolValue(v: AnyObject?) -> Bool?`:
	* for a `nil`, NSNull or unrecognized input, returns `nil`;
	* for a Bool input, returns that boolean value;
	* for an Int or NSNumber input, returns `true` if the number is non-zero, `false` otherwise;
	* for a String or NSString input, returns `true` if the string is `true`, `YES`, `Y`, `ON` or `1` (case-insensitive), `false` if the string is `false`, `NO`, `N`, `OFF` or `0` (case-insensitive), otherwise returns `nil`.

* `IntValue(v: AnyObject?) -> Int?`:
	* for a `nil`, NSNull or unrecognized input, returns `nil`;
	* for an Int or NSNumber input, returns that number;
	* for a String input convertible to Int, performs the conversion and returns the result.

* `DoubleValue(v: AnyObject?) -> Double?`:
	* for a `nil`, NSNull or unrecognized input, returns `nil`;
	* for a Double, Int or NSNumber input, returns that number;
	* for a String input convertible to Double, performs the conversion and returns the result.

* `StringValue(v: AnyObject?) -> String?`:
	* for a `nil`, NSNull or unrecognized input, returns `nil`;
	* for a String input, returns the string;
	* for a Double, Int or NSNumber input, returns the string representation of the number.

* `NonEmptyStringValue(v: AnyObject?, trimWhitespace: Bool = true) -> String?` — like `StringValue`, but:
	* trims the resulting string if `trimWhitespace` is `true` (the default);
	* returns `nil` instead of an empty string (i.e. if `trimWhitespace` is true, returns `nil` for whitespace-only and empty strings; if `trimWhitespace` is `false`, returns `nil` for empty strings, but can return a whitespace-only string).

* `NonEmptyString(v: String?, trimWhitespace: Bool = true) -> String?` is like `NonEmptyStringValue`, but for those cases when you already have a String and simply want to trim it and convert empty values to `nil`.


### Foundation value casts

* `URLValue(v: AnyObject?) -> NSURL?`:
	* for a `nil`, NSNull or unrecognized input, returns `nil`;
	* for a String input parsable as NSURL, returns the resulting NSURL object.


### Collection value casts

* `JSONObjectValue(v: AnyObject?) -> JSONObject?` returns a JSONObject value if that's what the input is, or `nil` otherwise.

	As a reminder, `JSONObject` is `[String: AnyObject]`, and this function simply does `v as? [String: AnyObject]`, so it doesn't do much — but may be clearer when used among other similar casting functions.

* `JSONObjectsArrayValue(v: AnyObject?) -> [JSONObject]?` returns an array of JSONObject values if that's what the input is, or `nil` otherwise.

* `ArrayValue(...) -> [T]?` returns an array of values converted with a given block if the input is an array, or `nil` otherwise.

	Usage example:

		let input: AnyObject? = ["1", " 2 ", " 3"]
		let result = ArrayValue(input) { IntValue($0) }
		// result is [1, 2, 3], of type [Int]?


### Fuzzy cast operator

Fuzzy cast operator (`~~~`) is a shorthand for calling one of the functions above; it uses the expected return value type to determine the casting function to use.

Compare:

    name = NonEmptyStringValue(raw["name")
    price = IntValue(raw["age"])
    url = URLValue(raw["url"])

and:

    name = raw["name"]~~~
    price = raw["price"]~~~
    url = raw["url"]~~~

Custom operators may be a conversial topic, but when processing a bunch of untyped data, there's a big value in keeping the code clean.

You don't have to use the operator if you don't like it. I encourage you to consider which approach leads to a more understandable code in your case.

For String values, the operator always uses `NonEmptyStringValue` with `trimWhitespace` set to `true`. Use `StringValue` explicitly if you want to distinguish between empty and missing strings. (The rationale is that NonEmptyStringValue is a safer choice, and the library is meant to parse data potentially generated by PHP or tamptered with by the user. You never know when they give you an empty string instead of a null you expected.)


## Usage (JSONObjectConvertible protocol)

To further simplify the code that parses a lot of structs (or classes), there's JSONObjectConvertible protocol:

    protocol JSONObjectConvertible {
        init(raw: JSONObject) throws
    }

and the following two functions:

* `JSONConvertibleObjectValue(v: AnyObject?) -> T?` — applies `JSONObjectValue` and, if the result is non-nil, uses `init(raw: JSONObject)` to convert the result to the expected type.

* `JSONConvertibleObjectsArrayValue(v: AnyObject?) -> [T]?` — applies `JSONObjectsArrayValue` and, if the result is non-nil, uses `init(raw: JSONObject)` to convert each element of the array to the expected type.

The `~~~` operator also supports these, so parsing an array of objects can be as simple as:

    widgets = raw["widgets"]~~~  // Widget is JSONObjectConvertible


### `??`

Use Swift's built-in `??` operator to add default values:

    name = NonEmptyStringValue(raw["name") ?? "Unnamed"
    price = IntValue(raw["age"]) ?? 0
    url = URLValue(raw["url"]) ?? kDefaultURL

or, better yet:

    name = raw["name"]~~~ ?? "Unnamed"
    price = raw["price"]~~~ ?? 0
    url = raw["url"]~~~ ?? kDefaultURL


### Expected return types

`~~~` uses the return type to determine the cast to run. Normally, you'll be assigning to a field and thus the type is already known, but sometimes you want to declare a new variable.

You can use `??` to specify the expected type for `~~~` operator:

		let v: AnyObject? = "1"
		let a = v~~~       // error: which type to convert to?
		let b = v~~~ ?? 1  // good, converts to Int

Of course, if you don't want a default value and still want to use `~~~`, you can specify the expected type some other way:

		let c = v~~~ as Int
		let d: Int = v~~~

The best way, though, is to assign to a field.


## Example

    enum ParsingError: ErrorType {
        case MissingArticleHeadline
        case MissingImageUrl
    }

    struct Article: JSONObjectConvertible {

        var headline: String
        var photos: [Photo]

        init(raw: JSONObject) throws {
            headline = raw["headline"]~~~ ?? ""
            photos = raw["photos"]~~~ ?? []

            if headline.isEmpty {
                throw ParsingError.MissingArticleHeadline
            }
        }
        
    }

    struct Photo: JSONObjectConvertible {

        var fullSizeImage: Image?
        var smallImage: Image?

        init(raw: JSONObject) {
            fullSizeImage = raw["full"]~~~
            smallImage = raw["small"]~~~
        }
        
    }

    struct Image: JSONObjectConvertible {

        var url: NSURL?
        var width: Int?
        var height: Int?

        init(raw: JSONObject) throws {
            url = raw["url"]~~~
            width = raw["width"]~~~
            height = raw["height"]~~~

            if url == nil {
                throw ParsingError.MissingImageUrl
            }
        }
        
    }


## Installation

Use CocoaPods:

		pod 'ExpressiveCasting', '~> 0.5`

or add this repository as a submodule, drag ExpressiveCasts.xcodeproj into your workspace, add it to “Link with libraries” build phase and then configure a “Copy files” build phase to copy it into the Frameworks folder of your target product (be sure to check the “code sign on copy” checkbox if your target uses code signing).

I'd love to add Carthage support some day. Pull requests welcome.

Using the new Swift Package Manager in development snapshots in Swift 3:

    let package = Package(
        ...
        dependencies: [
            ...
            .Package(url: "https://github.com/ExpressiveSwift/ExpressiveCasting.git", majorVersion: 0, minor: 5)
        ]
    )



## Contribution policy

Please do contribute. Two accepted pull requests give you a commit access.

I welcome support of all Swift and Foundation types.

I won't unnecessarily avoid merging pull requests that follow the spirit of the library.


## For maintainers

Release process:

1. Bump the version number in `.podspec`.

2. `make release`


## License

Copyright © 2014-2015, Andrey Tarantsov. Provided under the MIT license.
