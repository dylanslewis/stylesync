//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
@testable import StyleSyncCore

class TextStyleTests: XCTestCase {
	func testInitializingATextStyleWithNoLineHeightUsesTheFontsDefaultLineHeight() {
		let colorStyle = ColorStyle(
			name: "Color Style",
			identifier: "a",
			color: .red,
			isDeprecated: false
		)
		let textStyle = TextStyle(
			name: "Text Style",
			identifier: "0",
			groupedIdentifiers: nil,
			fontName: "DINAlternate-Bold",
			pointSize: 20,
			kerning: 0,
			lineHeight: 0,
			colorStyle: colorStyle,
			isDeprecated: false
		)
		
		let expectedLineHeight: CGFloat = 24
		XCTAssertEqual(textStyle.lineHeight, expectedLineHeight)
	}
}
