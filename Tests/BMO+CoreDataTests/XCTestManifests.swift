import XCTest

extension BMO_CoreDataTests {
    static let __allTests = [
        ("testCompoundPredicateConstantsEnumeration", testCompoundPredicateConstantsEnumeration),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BMO_CoreDataTests.__allTests),
    ]
}
#endif
