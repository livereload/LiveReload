import Foundation

enum VariableFoldingBehavior {
    case Folded
    case Accumulated
}

class Variable {

    init(name: String, foldingBehavior: VariableFoldingBehavior) {
    }

}

class VariableInstance {

}

class EvidenceSource {

}

struct Evidence {

    let value: AnyObject

}
