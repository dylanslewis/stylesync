//
//  StringTests.swift
//  StyleSync
//
//  Created by Dylan Lewis on 02/09/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import XCTest
import StyleSyncCore

class StringTests: XCTestCase {
	// MARK: Camelcased
	
	func testCamelcasedStringRemainsTheSame() {
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
	
	// MARK: Lowercased with underscore separators
	
	func testLowercasedWithUnderscoreSeparatorsRemainsTheSame() {
		let originalString = "lowercased_underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoCapitalizedWordsSeparatedByASpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "Lowercased Underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoLowercasedWordsSeparatedByASpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoUppercasedWordsSeparatedByASpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "LOWERCASED UNDERSCORED"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoWordsWithASpaceAtTheEndAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased underscored "
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoWordsWithAnUnderscoreSurroundedBySpaceAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased _ underscored"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	func testTwoWordsWithAnUnderscoreAfterEachWordAreLowercasedWithUnderscoreSeparatorsCorrectly() {
		let originalString = "lowercased_ underscored_"
		let expectedString = "lowercased_underscored"
		XCTAssertEqual(originalString.lowercasedWithUnderscoreSeparators, expectedString)
	}
	
	// MARK: Capitalized without space separators
	
	func testCapitalizedWithoutSpaceSeparatorsRemainsTheSame() {
		let originalString = "CapitalizedSpace"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoCapitalizedWordsSeparatedByASpaceAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "Capitalized Space"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoLowercasedWordsSeparatedByASpaceAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "capitalized space"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoUppercasedWordsSeparatedByASpaceAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "CAPITALIZED SPACE"
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
	
	func testTwoWordsWithASpaceAtTheEndAreCapitalizedWithoutSpaceSeparatorsCorrectly() {
		let originalString = "capitalized space "
		let expectedString = "CapitalizedSpace"
		XCTAssertEqual(originalString.capitalizedWithoutSpaceSeparators, expectedString)
	}
}
