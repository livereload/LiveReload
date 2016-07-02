public protocol Updateable: class {

    func update()

    func enumerateUpdateableChildren() -> AnySequence<Updateable>

}

public extension Updateable {

}
