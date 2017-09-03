//
//  VersionTests.swift
//  StyleSyncTests
//
//  Created by Dylan Lewis on 03/09/2017.
//

import XCTest
@testable import StyleSyncCore

class VersionTests: XCTestCase {
	func testCreatingVersionWithNoVersionIsVersionOne() {
		let version = Version(oldColorStyles: nil, oldTextStyles: nil, newColorStyles: [], newTextStyles: [], currentVersion: nil)
		let expectedVersion = Version(major: 1, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testCreatingVersionWithInvalidStringReturnsNil() {
		let version = Version(versionString: "1")
		XCTAssertNil(version)
	}
	
	func testCreatingVersionWithValidStringReturnsVersion() {
		let version = Version(versionString: "1.0")
		XCTAssertNotNil(version)
	}
	
	func testStringRepresentationOfAVersionIsWellFormatted() {
		let version = Version(major: 1, minor: 2)
		let stringRepresentation = version.stringRepresentation
		let expectedVersionString = "1.2"
		XCTAssertEqual(stringRepresentation, expectedVersionString)
	}
	
	func testIncrementingMajorVersionReturnsCorrectVersion() {
		let version = Version(major: 1, minor: 0)
		let incrementedMajorVersion = version.incrementingMajor()
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(incrementedMajorVersion, expectedVersion)
	}
	
	func testIncrementingMinorVersionReturnsCorrectVersion() {
		let version = Version(major: 1, minor: 0)
		let incrementedMinorVersion = version.incrementingMinor()
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(incrementedMinorVersion, expectedVersion)
	}
	
	func testIncrementingMajorVersionResetsMinorVersion() {
		let version = Version(major: 1, minor: 1)
		let incrementedMajorVersion = version.incrementingMajor()
		let expectedMinorVersion = 0
		XCTAssertEqual(incrementedMajorVersion.minor, expectedMinorVersion)
	}
	
	private let redColorStyle = ColorStyle(name: "Red", identifier: "1", color: .red, isDeprecated: false)
	private let greenColorStyle = ColorStyle(name: "Green", identifier: "2", color: .green, isDeprecated: false)
	private var newRedColorStyle: ColorStyle {
		return .init(
			name: "New Red",
			identifier: redColorStyle.identifier,
			color: redColorStyle.color,
			isDeprecated: redColorStyle.isDeprecated
		)
	}
	
	private var headingTextStyle: TextStyle {
		return .init(
			name: "Heading",
			identifier: "1",
			fontName: "Font",
			pointSize: 20,
			kerning: 1,
			lineHeight: 24,
			colorStyle: redColorStyle,
			isDeprecated: false
		)
	}
	private var bodyTextStyle: TextStyle {
		return .init(
			name: "Body",
			identifier: "2",
			fontName: "Font",
			pointSize: 16,
			kerning: 1,
			lineHeight: 20,
			colorStyle: greenColorStyle,
			isDeprecated: false
		)
	}
	private var newHeadingTextStyle: TextStyle {
		return .init(
			name: "New Heading",
			identifier: headingTextStyle.identifier,
			fontName: headingTextStyle.fontName,
			pointSize: headingTextStyle.pointSize,
			kerning: headingTextStyle.kerning,
			lineHeight: headingTextStyle.lineHeight,
			colorStyle: headingTextStyle.colorStyle,
			isDeprecated: headingTextStyle.isDeprecated
		)
	}
	
	func testRemovingAColorStyleIncrementsMajorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle]
		let newColorStyles = [redColorStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testAddingAColorStyleIncrementsMinorVersion() {
		let oldColorStyles = [redColorStyle]
		let newColorStyles = [redColorStyle, greenColorStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testKeepingColorStylesUnchangedDoesNotChangeVersion() {
		let oldColorStyles = [redColorStyle]
		let newColorStyles = [redColorStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testUpdatingAnExistingColorStyleIncrementsMinorVersion() {
		let oldColorStyles = [redColorStyle]
		let newColorStyles = [newRedColorStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testRemovingATextStyleIncrementsMajorVersion() {
		let oldTextStyles = [headingTextStyle, bodyTextStyle]
		let newTextStyles = [headingTextStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testAddingATextStyleIncrementsMinorVersion() {
		let oldTextStyles = [headingTextStyle]
		let newTextStyles = [headingTextStyle, bodyTextStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testKeepingTextStylesUnchangedDoesNotChangeVersion() {
		let oldTextStyles = [headingTextStyle]
		let newTextStyles = [headingTextStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testUpdatingAnExistingTextStyleIncrementsMinorVersion() {
		let oldTextStyles = [headingTextStyle]
		let newTextStyles = [newHeadingTextStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testUpdatingAColorStyleAndAddingATextStyleIncrementsMinorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle]
		let oldTextStyles = [headingTextStyle]
		let newColorStyles = [newRedColorStyle, greenColorStyle]
		let newTextStyles = [headingTextStyle, bodyTextStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testRemovingAColorStyleAndAddingATextStyleIncrementsMajorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle]
		let oldTextStyles = [headingTextStyle]
		let newColorStyles = [redColorStyle]
		let newTextStyles = [headingTextStyle, bodyTextStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testRemovingAColorStyleAndUpdatingATextStyleIncrementsMajorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle]
		let oldTextStyles = [headingTextStyle, bodyTextStyle]
		let newColorStyles = [redColorStyle]
		let newTextStyles = [newHeadingTextStyle, bodyTextStyle]
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			currentVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
}
