import Foundation
import Uniflow

public class ActionOptions : NSObject {
    
    public let actionIdentifier: String

    public var globalOptions: [String: AnyObject] = [:] {
        didSet {
            ChangeBus.didChange()
        }
    }

    private var fileOptions: [String: FileCompilationOptions] = [:]
    private var includeDirectories: [AnyObject]?
    
    public var additionalArguments: String {
        didSet {
            ChangeBus.didChange()
        }
    }

    var enabled: Bool?
    var availableVersions: [AnyObject]?
    var availableVersions: [AnyObject]?
    var isEnabled: Bool?
    var isActive: Bool?
    var additionalArguments: String?
    var allFileOptions: [AnyObject]?
    
    // MARK: init/dealloc
    public override init(actionIdentifier: String, memento: [NSObject : AnyObject]) {
        super.init()
        self.actionIdentifier = actionIdentifier
        _fileOptions = NSMutableDictionary()
        let raw: AnyObject = memento["options"]
        if raw {
            _globalOptions.valuesForKeysWithDictionary = raw
        }
        raw = memento["files"]
        if raw {
            raw.enumerateKeysAndObjectsUsingBlock({ (filePath: AnyObject, fileMemento: AnyObject, stop: Bool) in
                _fileOptions[filePath] = FileCompilationOptions(file: filePath, memento: fileMemento).autorelease()
                
            })
        }
        raw = memento["additionalArguments"]
        if raw {
            _additionalArguments = raw.copy()
        } else {
            _additionalArguments = ""
            
        }
        raw = memento["enabled2"]
        if raw {
            _enabled = raw.boolValue()
        } else if !!(raw = memento["enabled"]) {
            _enabled = raw.boolValue()
        } else {
            _enabled = false
            
        }
    }
    
    // MARK: - Persistence
    func memento() -> [NSObject : AnyObject] {
        return NSDictionary(objectsAndKeys: _globalOptions,"options",_fileOptions.dictionaryByMappingValuesToSelector("memento"),"files",_additionalArguments,"additionalArguments",NSNumber(bool: _enabled),"enabled",NSNumber(bool: _enabled),"enabled2",nil)
    }
    
    func valueForOptionIdentifier(optionIdentifier: String) -> AnyObject {
        return _globalOptions[optionIdentifier]
    }
    
    func setValue(value: AnyObject, forOptionIdentifier optionIdentifier: String) {
        _globalOptions[optionIdentifier] = value
        NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: self)
    }
    
    // MARK: - File options
    func optionsForFileAtPath(path: String, create create: Bool) -> FileCompilationOptions {
        let result: FileCompilationOptions = _fileOptions[path]
        if result == nil && create {
            result = FileCompilationOptions(file: path, memento: nil).autorelease()
            _fileOptions[path] = result
            NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: self)
        }
        return result
    }
    
    func sourcePathThatCompilesInto(outputPath: String) -> String {
        let result: String = nil
        _fileOptions.enumerateKeysAndObjectsUsingBlock({ (key: AnyObject, obj: AnyObject, stop: Bool) in
            let fileOptions: FileCompilationOptions = obj
            if fileOptions.enabled && fileOptions.destinationPath == outputPath {
                result = key
                *stop = true
            }
            
        })
        return result
    }
    
    func allFileOptions() -> [AnyObject] {
        return _fileOptions.allValues()
    }
    
    // MARK: - Enabled
    func setEnabled(enabled: Bool) {
        if enabled != _enabled {
            _enabled = enabled
            NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object: self)
        }
    }
    
    func isActive() -> Bool {
        return _enabled
    }
    
}

