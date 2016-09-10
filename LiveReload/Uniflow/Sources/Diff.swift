//public func diff<K: Identifiable>(oldList: [K], _ newList: [K]) {
//    let oldMap = oldList.indexBy { $0.uniqueIdentifier }
//    let newMap = newList.indexBy { $0.uniqueIdentifier }
//    
//    for (idx, el) in oldList.enumerate() {
//        print("element at \(idx) is \(el)")
//    }
//    for newItem in newList {
//        
//    }
//}
//
////public func updateMap<K: Identifiable, V>() {
////
////}
//
//public struct Diff<T> {
//    
//}
//
//public enum ListEdit {
//    
//    
//    
//}
//
//public struct Removal<T> {
//    
//    public let oldIndex: Int
//    
//    public let oldElement: T
//    
//}
//
//public struct Addition<T> {
//    
//    public let newIndex: Int
//    
//}
//
//private extension SequenceType {
//    
//    func indexBy<T: Hashable>(block: (Self.Generator.Element) throws -> T?) rethrows -> [T: Self.Generator.Element] {
//        var map: [T: Self.Generator.Element] = [:]
//        for item in self {
//            if let id = try block(item) {
//                map[id] = item
//            }
//        }
//        return map
//    }
//    
//}
