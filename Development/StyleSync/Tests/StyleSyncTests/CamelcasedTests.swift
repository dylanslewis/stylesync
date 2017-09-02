//
//  CamelcasedTests.swift
//  StyleSync
//
//  Created by Dylan Lewis on 02/09/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation
import XCTest
import StyleSyncCore

class CamelcasedTests: XCTestCase {
	func testCamelcasedStringRemainsCamelcased() {
		let originalString = "camelCased"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoCapitalizedWordsSeparatedByASpaceAreCamelcasedCorrectly() {
		let originalString = "Camel Cased"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoLowercasedWordsSeparatedByASpaceAreCamelcasedCorrectly() {
		let originalString = "camel cased"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoUppercasedWordsSeparatedByASpaceAreCamelcasedCorrectly() {
		let originalString = "CAMEL CASED"
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
	
	func testTwoWordsWithASpaceAtTheEndAreCamelcasedCorrectly() {
		let originalString = "camel cased "
		let expectedString = "camelCased"
		XCTAssertEqual(originalString.camelcased, expectedString)
	}
}
