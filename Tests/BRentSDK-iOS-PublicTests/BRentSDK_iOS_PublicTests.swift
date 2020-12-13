import XCTest
@testable import BRentSDK_iOS_Public

final class BRentSDK_iOS_PublicTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BRentSDK_iOS_Public().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
