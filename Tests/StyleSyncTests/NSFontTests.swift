//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
@testable import StyleSyncCore

class NSFontTests: XCTestCase {
	func testDefaultLineHeightOfFontIsTheCorrectValue() {
		let lineHeight = NSFont.defaultLineHeight(fontName: "DINAlternate-Bold", pointSize: 20)
		let expectedLineHeight: CGFloat = 24
		XCTAssertEqual(lineHeight, expectedLineHeight)
	}
}
