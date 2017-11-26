//
//  NSFontTests.swift
//  StyleSyncTests
//
//  Created by Dylan Lewis on 26/11/2017.
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
