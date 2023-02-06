import XCTest
@testable import micrograd

final class microgradTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(micrograd().text, "Hello, World!")
    }
}
