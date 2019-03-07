import XCTest

extension RESTColorTransformerTests {
    static let __allTests = [
        ("testSimpleFail", testSimpleFail),
        ("testSimpleHexColorWithoutSharpConversion", testSimpleHexColorWithoutSharpConversion),
        ("testSimpleHexColorWithSharpConversion", testSimpleHexColorWithSharpConversion),
    ]
}

extension RESTNumericTransformerTest {
    static let __allTests = [
        ("testWeirdFloatNumberToFloatConversion", testWeirdFloatNumberToFloatConversion),
    ]
}

extension RESTUtilsTests {
    static let __allTests = [
        ("testConstantAndVariableRESTPath", testConstantAndVariableRESTPath),
        ("testConstantRESTPath", testConstantRESTPath),
        ("testEmptySubpathRESTPath", testEmptySubpathRESTPath),
        ("testEmptyVariableRESTPath", testEmptyVariableRESTPath),
        ("testInvalidPath1", testInvalidPath1),
        ("testInvalidPath10", testInvalidPath10),
        ("testInvalidPath11", testInvalidPath11),
        ("testInvalidPath2", testInvalidPath2),
        ("testInvalidPath3", testInvalidPath3),
        ("testInvalidPath4", testInvalidPath4),
        ("testInvalidPath5", testInvalidPath5),
        ("testInvalidPath6", testInvalidPath6),
        ("testInvalidPath7", testInvalidPath7),
        ("testInvalidPath8", testInvalidPath8),
        ("testInvalidPath9", testInvalidPath9),
        ("testOpenParenthesisVariableRESTPath", testOpenParenthesisVariableRESTPath),
        ("testSimpleAbsentOptionalVariableReplacement", testSimpleAbsentOptionalVariableReplacement),
        ("testSimpleAbsentVariableReplacement", testSimpleAbsentVariableReplacement),
        ("testSimpleVariableReplacement", testSimpleVariableReplacement),
        ("testTwoLevelsKeyPathVariableReplacement", testTwoLevelsKeyPathVariableReplacement),
        ("testTwoLevelsKeyPathVariableReplacement2", testTwoLevelsKeyPathVariableReplacement2),
        ("testVariableRESTPath", testVariableRESTPath),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RESTColorTransformerTests.__allTests),
        testCase(RESTNumericTransformerTest.__allTests),
        testCase(RESTUtilsTests.__allTests),
    ]
}
#endif
