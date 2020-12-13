import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BRentSDK_iOS_PublicTests.allTests),
    ]
}
#endif
