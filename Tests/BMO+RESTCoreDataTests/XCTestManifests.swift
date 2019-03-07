import XCTest

extension BMO_RESTCoreDataTests {
    static let __allTests = [
        ("testExample", testExample),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BMO_RESTCoreDataTests.__allTests),
    ]
}
#endif
