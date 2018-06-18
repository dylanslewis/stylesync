//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
@testable import StyleSyncCore
import Files

class StyleExtractorTests: XCTestCase {
	// MARK: - Constants
	
	private enum Constant {
		static let colorStyle = "Color Style"
		static let textStyle = "Text Style"
		static let colorStyleIdentifier = "123"
		static let textStyleIdentifier = "1234"
		static let exportedColorStylesName = "exportedColorStyles.json"
		static let exportedTextStylesName = "exportedTextStyles.json"
	}
	
	// MARK: - Stored variables
	
	private let currentFolder = Folder.current
	
	// MARK: - Computed variables
	
	private var previouslyExportedTextStyles: File {
		do {
			return try currentFolder.file(named: Constant.exportedTextStylesName)
		} catch {
			return try! currentFolder.createFile(named: Constant.exportedTextStylesName)
		}
	}
	
	private var previouslyExportedColorStyles: File {
		do {
			return try currentFolder.file(named: Constant.exportedColorStylesName)
		} catch {
			return try! currentFolder.createFile(named: Constant.exportedColorStylesName)
		}
	}
	
	// MARK: - Overrides
	
	override func tearDown() {
		// Remove the previously generated style files.
		do {
			try previouslyExportedTextStyles.delete()
		} catch {
			print(error)
		}
		do {
			try previouslyExportedColorStyles.delete()
		} catch {
			print(error)
		}
		super.tearDown()
	}
	
	// MARK: - Tests
	
	// FIXME: Add tests for namespaced styles
	
	func testWhenPreviouslyExportedStylesFilesAreCreatedThenPreviouslyExportedStylesVersionReadCorrectly() {
		createPreviouslyExportedStylesFiles(textStyles: [], colorStyles: [])

		let sketchDocument = self.sketchDocument()
		let styleExtractor = StyleExtractor(
			generatedRawTextStylesFile: previouslyExportedTextStyles,
			generatedRawColorStylesFile: previouslyExportedColorStyles,
			sketchDocument: sketchDocument
		)
	
		let expectedPreviouslyExportedVersion: Version = .firstVersion
		XCTAssertEqual(styleExtractor.previousStylesVersion, expectedPreviouslyExportedVersion)
	}
	
	func testWhenNoPreviouslyExportedStylesFilesAreCreatedThenPreviouslyExportedStylesVersionIsNil() {
		let sketchDocument = self.sketchDocument()
		let styleExtractor = StyleExtractor(
			generatedRawTextStylesFile: previouslyExportedTextStyles,
			generatedRawColorStylesFile: previouslyExportedColorStyles,
			sketchDocument: sketchDocument
		)
		
		XCTAssertNil(styleExtractor.previousStylesVersion)
	}
	
	func testSketchDocumentStylesAreReadCorrectly() {
		let sketchDocument = self.sketchDocument()
		let styleExtractor = StyleExtractor(
			generatedRawTextStylesFile: previouslyExportedTextStyles,
			generatedRawColorStylesFile: previouslyExportedColorStyles,
			sketchDocument: sketchDocument
		)
		
		XCTAssertEqual(styleExtractor.latestColorStyles.count, 1)
		XCTAssertEqual(styleExtractor.latestTextStyles.count, 1)
	}
	
	func testTextStyleThatDoesNotUseASharedColorStyleIsNotExtracted() {
		let sketchDocument = self.sketchDocument(sharedColor: .green, textColor: .blue)
		let styleExtractor = StyleExtractor(
			generatedRawTextStylesFile: previouslyExportedTextStyles,
			generatedRawColorStylesFile: previouslyExportedColorStyles,
			sketchDocument: sketchDocument
		)
		
		XCTAssertEqual(styleExtractor.latestTextStyles.count, 0)
	}
	
	// MARK: - Helpers
	
	private func createPreviouslyExportedStylesFiles(
		textStyles: [TextStyle],
		colorStyles: [ColorStyle],
		version: Version = .firstVersion
	) {
		let previouslyExportedTextStyles = VersionedStyle.Text(version: version, textStyles: textStyles)
		let previouslyExportedColorStyles = VersionedStyle.Color(version: version, colorStyles: colorStyles)
		
		let encoder = JSONEncoder()
		do {
			let previouslyExportedTextStylesData = try encoder.encode(previouslyExportedTextStyles)
			let previouslyExportedColorStylesData = try encoder.encode(previouslyExportedColorStyles)
			
			try currentFolder.createFile(
				named: Constant.exportedTextStylesName,
				contents: previouslyExportedTextStylesData
			)
			try currentFolder.createFile(
				named: Constant.exportedColorStylesName,
				contents: previouslyExportedColorStylesData
			)
		} catch {
			XCTFailAndAbort(error.localizedDescription)
		}
	}
	
	private func sketchDocument(sharedColor: NSColor = .red, textColor: NSColor = .red) -> SketchDocument {
		let colorStyle = sketchDocumentColorObject(
			name: Constant.colorStyle,
			identifier: Constant.colorStyleIdentifier,
			color: sharedColor
		)
		let textStyle = sketchDocumentTextObject(
			name: Constant.textStyle,
			identifier: Constant.textStyleIdentifier,
			color: textColor
		)
		
		let colorStyles = SketchDocument.ColorStyles(objects: [colorStyle])
		let textStyles = SketchDocument.TextStyles(objects: [textStyle])
		
		return SketchDocument(
			layerStyles: colorStyles,
			layerTextStyles: textStyles
		)
	}
	
	private func sketchDocumentColorObject(name: String, identifier: String, color: NSColor) -> SketchDocument.ColorStyles.Object {
		let sketchColor = SketchDocument.ColorStyles.Object.Value.Fill.Color(
			red: color.redComponent,
			green: color.greenComponent,
			blue: color.blueComponent,
			alpha: color.alphaComponent
		)
		let colorFill = SketchDocument.ColorStyles.Object.Value.Fill(color: sketchColor)
		return SketchDocument.ColorStyles.Object(
			name: name,
			value: SketchDocument.ColorStyles.Object.Value(fills: [colorFill]),
			identifier: identifier
		)
	}
	
	private func sketchDocumentTextObject(name: String, identifier: String, color: NSColor) -> SketchDocument.TextStyles.Object {
		let sketchFontAttributes = SketchDocument.TextStyles.Object.Value.TextStyle.EncodedAttributes.Font.Attributes(
			fontName: "DINAlternate-Bold",
			pointSize: 16
		)
		let sketchFont = SketchDocument.TextStyles.Object.Value.TextStyle.EncodedAttributes.Font(attributes: sketchFontAttributes)
		let sketchParagraphStyle = SketchDocument.TextStyles.Object.Value.TextStyle.EncodedAttributes.ParagraphStyle(
			textAlignment: .left,
			minimumLineHeight: 17,
			maximumLineHeight: 17
		)
		
		let encodedAttributes = SketchDocument.TextStyles.Object.Value.TextStyle.EncodedAttributes(
			font: sketchFont,
			color: color,
			paragraphStyle: sketchParagraphStyle,
			kerning: 0
		)
		let textStyle = SketchDocument.TextStyles.Object.Value.TextStyle(encodedAttributes: encodedAttributes)
		
		return SketchDocument.TextStyles.Object(
			name: name,
			value: SketchDocument.TextStyles.Object.Value(textStyle: textStyle),
			identifier: identifier
		)
	}
}
