import Cocoa
import XCTest
import VariableKit

class VariableKitTests: XCTestCase {

    func testExample() {
        let fooDef = VariableDefinition(name: "Foo", scope: .File, foldingBehavior: .Folded)
        let alpha = EvidenceSource(name: "Alpha")
        let varSet = VariableSet(variableDefinitions: [fooDef], sources: [alpha])
        let foo = varSet.lookupVariable(definition: fooDef)!

        let values1 = varSet.newValueSet(scope: .File)
        values1.replaceEvidence(source: alpha, newEvidence: Evidence(variable: foo, source: alpha, value: 42, priority: 0, reason: "Blah"))
        let v = values1.getFolded(variable: foo, defaultValue: -1) as! Int
        XCTAssertEqual(v, 42)
    }

}
