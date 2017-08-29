import Foundation
import XCTest
import StyleSyncCore

class StyleSyncTests: XCTestCase {
	func testRunningAFailingTest() {
		XCTAssertNotNil("")
	}
	
	func testSomething() {
		let string = "string String".camelcased
		XCTAssertEqual(string, "stringString")
	}
}
