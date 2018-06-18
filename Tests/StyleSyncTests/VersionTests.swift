//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
@testable import StyleSyncCore

class VersionTests: XCTestCase {
	func testCreatingVersionWithNoVersionIsVersionOne() {
		let version = Version(oldColorStyles: nil, oldTextStyles: nil, newColorStyles: [], newTextStyles: [], previousStylesVersion: nil)
		let expectedVersion = Version(major: 1, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testCreatingVersionWithInvalidStringReturnsNil() {
		let version = Version(versionString: "")
		XCTAssertNil(version)
	}
	
	func testCreatingVersionWithOnlyMajorStringReturnsVersion() {
		let version = Version(versionString: "1")
		XCTAssertNotNil(version)
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
	
	func testComparingEqualVersionsWithNoMinorReturnsCorrectValue() {
		let lhsVersion = Version(major: 1, minor: 0)
		let rhsVersion = Version(major: 1, minor: 0)
		XCTAssertTrue(lhsVersion == rhsVersion)
	}
	
	func testComparingEqualVersionsWithMinorReturnsCorrectValue() {
		let lhsVersion = Version(major: 1, minor: 1)
		let rhsVersion = Version(major: 1, minor: 1)
		XCTAssertTrue(lhsVersion == rhsVersion)
	}
	
	func testComparingLargerMajorVersionReturnsCorrectValue() {
		let lhsVersion = Version(major: 2, minor: 0)
		let rhsVersion = Version(major: 1, minor: 0)
		XCTAssertTrue(lhsVersion > rhsVersion)
	}
	
	func testComparingLargerMinorVersionReturnsCorrectValue() {
		let lhsVersion = Version(major: 1, minor: 1)
		let rhsVersion = Version(major: 1, minor: 0)
		XCTAssertTrue(lhsVersion > rhsVersion)
	}
	
	func testComparingLargerMinorButSmallerMajorReturnCorrectValue() {
		let lhsVersion = Version(major: 2, minor: 0)
		let rhsVersion = Version(major: 1, minor: 1)
		XCTAssertTrue(lhsVersion > rhsVersion)
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
			groupedIdentifiers: nil,
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
			groupedIdentifiers: nil,
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
			groupedIdentifiers: nil,
			fontName: headingTextStyle.fontName,
			pointSize: headingTextStyle.pointSize,
			kerning: headingTextStyle.kerning,
			lineHeight: headingTextStyle.lineHeight,
			colorStyle: headingTextStyle.colorStyle,
			isDeprecated: headingTextStyle.isDeprecated
		)
	}
	
	func testRemovingAColorStyleIncrementsMajorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle].convertedToCodeTemplateReplacableStyle
		let newColorStyles = [redColorStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testAddingAColorStyleIncrementsMinorVersion() {
		let oldColorStyles = [redColorStyle].convertedToCodeTemplateReplacableStyle
		let newColorStyles = [redColorStyle, greenColorStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testKeepingColorStylesUnchangedDoesNotChangeVersion() {
		let oldColorStyles = [redColorStyle].convertedToCodeTemplateReplacableStyle
		let newColorStyles = [redColorStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testUpdatingAnExistingColorStyleIncrementsMinorVersion() {
		let oldColorStyles = [redColorStyle].convertedToCodeTemplateReplacableStyle
		let newColorStyles = [newRedColorStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: [],
			newColorStyles: newColorStyles,
			newTextStyles: [],
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testRemovingATextStyleIncrementsMajorVersion() {
		let oldTextStyles = [headingTextStyle, bodyTextStyle].convertedToCodeTemplateReplacableStyle
		let newTextStyles = [headingTextStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testAddingATextStyleIncrementsMinorVersion() {
		let oldTextStyles = [headingTextStyle].convertedToCodeTemplateReplacableStyle
		let newTextStyles = [headingTextStyle, bodyTextStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testKeepingTextStylesUnchangedDoesNotChangeVersion() {
		let oldTextStyles = [headingTextStyle].convertedToCodeTemplateReplacableStyle
		let newTextStyles = [headingTextStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testUpdatingAnExistingTextStyleIncrementsMinorVersion() {
		let oldTextStyles = [headingTextStyle].convertedToCodeTemplateReplacableStyle
		let newTextStyles = [newHeadingTextStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: [],
			oldTextStyles: oldTextStyles,
			newColorStyles: [],
			newTextStyles: newTextStyles,
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testUpdatingAColorStyleAndAddingATextStyleIncrementsMinorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle].convertedToCodeTemplateReplacableStyle
		let oldTextStyles = [headingTextStyle].convertedToCodeTemplateReplacableStyle
		let newColorStyles = [newRedColorStyle, greenColorStyle].convertedToCodeTemplateReplacableStyle
		let newTextStyles = [headingTextStyle, bodyTextStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 1, minor: 1)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testRemovingAColorStyleAndAddingATextStyleIncrementsMajorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle].convertedToCodeTemplateReplacableStyle
		let oldTextStyles = [headingTextStyle].convertedToCodeTemplateReplacableStyle
		let newColorStyles = [redColorStyle].convertedToCodeTemplateReplacableStyle
		let newTextStyles = [headingTextStyle, bodyTextStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	func testRemovingAColorStyleAndUpdatingATextStyleIncrementsMajorVersion() {
		let oldColorStyles = [redColorStyle, greenColorStyle].convertedToCodeTemplateReplacableStyle
		let oldTextStyles = [headingTextStyle, bodyTextStyle].convertedToCodeTemplateReplacableStyle
		let newColorStyles = [redColorStyle].convertedToCodeTemplateReplacableStyle
		let newTextStyles = [newHeadingTextStyle, bodyTextStyle].convertedToCodeTemplateReplacableStyle
		let currentVersion: Version = .firstVersion
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			previousStylesVersion: currentVersion
		)
		let expectedVersion = Version(major: 2, minor: 0)
		XCTAssertEqual(version, expectedVersion)
	}
	
	// FIXME: Add tests for name spaced styles
}

private extension Array where Element == ColorStyle {
	var convertedToCodeTemplateReplacableStyle: [CodeTemplateReplacableStyle] {
		return self.map({ CodeTemplateReplacableStyle(colorStyle: $0, fileType: "") })
	}
}

private extension Array where Element == TextStyle {
	var convertedToCodeTemplateReplacableStyle: [CodeTemplateReplacableStyle] {
		return self.map({ CodeTemplateReplacableStyle(textStyle: $0, fileType: "") })
	}
}
