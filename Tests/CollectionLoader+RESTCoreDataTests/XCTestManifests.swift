import XCTest

extension CollectionLoader_RESTCoreDataTests {
    static let __allTests = [
        ("testExample", testExample),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CollectionLoader_RESTCoreDataTests.__allTests),
    ]
}
#endif
