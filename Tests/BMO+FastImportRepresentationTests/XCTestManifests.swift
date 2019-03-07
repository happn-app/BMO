import XCTest

extension BMO_FastImportRepresentationTests {
    static let __allTests = [
        ("testExample", testExample),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BMO_FastImportRepresentationTests.__allTests),
    ]
}
#endif
