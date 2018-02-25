//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
import StyleSyncCore
import Files

class SketchManagerTests: XCTestCase {
	override func tearDown() {
		super.tearDown()
		
		// Always remove the unzipped files directory, incase any of the tests
		// fail to parse.
		if let leftOverFolder = try? testResources.subfolder(named: "UnzippedSketchFiles") {
			do {
				try leftOverFolder.delete()
			} catch {
				XCTFail("Failed to remove left over folder.")
			}
		}
	}
	
	func testSketchFileWithOneTextStyleIsParsedCorrectly() throws {
		let sketchDocument = try self.sketchDocument(withName: "SketchFileWithOneTextStyle")
		
		guard let textStyle = sketchDocument.layerTextStyles.objects.first else {
			return XCTFail("Failed to find text style")
		}
		
		let encodedAttributes = textStyle.value.textStyle.encodedAttributes
		
		let font = encodedAttributes.font
		XCTAssertEqual(font.fontName, "DINAlternate-Bold")
		XCTAssertEqual(font.pointSize, 16)
		
		let expectedColor = NSColor(red: 100/255, green: 110/255, blue: 120/255, alpha: 0.9)
		XCTAssertEqual(encodedAttributes.color, expectedColor)
		
		let paragraphStyle = encodedAttributes.paragraphStyle.paragraphStyle
		XCTAssertEqual(paragraphStyle?.alignment, .right)
		XCTAssertEqual(paragraphStyle?.minimumLineHeight, 20)
		XCTAssertEqual(paragraphStyle?.maximumLineHeight, 20)
		
		XCTAssertEqual(encodedAttributes.kerning, 1)
		
		XCTAssertEqual(textStyle.name, "Text Style")
		XCTAssertEqual(textStyle.identifier, "6EA180B8-F473-4255-8192-436F985208CF")
	}
	
	func testSketchFileWithOneColorStyleIsParsedCorrectly() throws {
		let sketchDocument = try self.sketchDocument(withName: "SketchFileWithOneColorStyle")
		
		guard let colorStyle = sketchDocument.layerStyles.objects.first else {
			return XCTFail("Failed to find color style")
		}
		
		XCTAssertEqual(colorStyle.name, "Color Style")
		XCTAssertEqual(colorStyle.identifier, "7F60C768-6A17-43A5-BCCF-3DCAEBE09268")
		
		guard let color = colorStyle.value.fills.first?.color else {
			return XCTFail("Failed to find fill color")
		}
		
		let expectedRed: CGFloat = 100/255
		let expectedGreen: CGFloat = 110/255
		let expectedBlue: CGFloat = 120/255

		// Need to round to be able to compare
		let numberOfPlacesToRoundTo = 10
		
		XCTAssertEqual(color.red.rounded(toPlaces: numberOfPlacesToRoundTo), expectedRed.rounded(toPlaces: numberOfPlacesToRoundTo))
		XCTAssertEqual(color.green.rounded(toPlaces: numberOfPlacesToRoundTo), expectedGreen.rounded(toPlaces: numberOfPlacesToRoundTo))
		XCTAssertEqual(color.blue.rounded(toPlaces: numberOfPlacesToRoundTo), expectedBlue.rounded(toPlaces: numberOfPlacesToRoundTo))
		XCTAssertEqual(color.alpha, 0.9)
	}

	func testSketchFileWithNoSharedTextStylesIsParsedCorrectly() throws {
		let sketchDocument = try self.sketchDocument(withName: "SketchFileWithNoStyles")

		XCTAssertEqual(sketchDocument.layerTextStyles.objects.count, 0)
		XCTAssertEqual(sketchDocument.layerStyles.objects.count, 0)
	}

	func testSketchFileWithFiveTextStylesAndFiveColorStylesIsParsedCorrectlyPreVersion48() throws {
		let sketchDocument = try self.sketchDocument(withName: "SketchFileWithFiveTextStylesAndFiveColorStylesPreVersion48")

		XCTAssertEqual(sketchDocument.layerTextStyles.objects.count, 5)
		XCTAssertEqual(sketchDocument.layerStyles.objects.count, 5)
	}
	
	func testSketchFileWithFiveTextStylesAndFiveColorStylesIsParsedCorrectlyPostVersion48() throws {
		let sketchDocument = try self.sketchDocument(withName: "SketchFileWithFiveTextStylesAndFiveColorStylesPostVersion48")
		
		XCTAssertEqual(sketchDocument.layerTextStyles.objects.count, 5)
		XCTAssertEqual(sketchDocument.layerStyles.objects.count, 5)
	}
	
	// MARK: - Helpers
	
	private func sketchDocument(withName name: String) throws -> SketchDocument {
		let sketchFile = try testResources.file(named: "\(name).sketch")
		let sketchManager = SketchManager(sketchFile: sketchFile)
		return try sketchManager.getSketchDocument()
	}
}
