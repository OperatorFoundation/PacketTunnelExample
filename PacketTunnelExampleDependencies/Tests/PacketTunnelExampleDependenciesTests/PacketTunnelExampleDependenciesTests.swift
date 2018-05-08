import XCTest
@testable import PacketTunnelExampleDependencies

final class PacketTunnelExampleDependenciesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PacketTunnelExampleDependencies().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
