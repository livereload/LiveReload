import Foundation

public class DailyStatisticsStore: NSObject {
    
    private let storage: KeyValueStore
    
    public init(storage: KeyValueStore) {
        self.storage = storage
        super.init()
    }
    
    public func incrementCounter(name: String) {
          
    }
    
    public func setFlag(name: String) {
        
    }
    
}
