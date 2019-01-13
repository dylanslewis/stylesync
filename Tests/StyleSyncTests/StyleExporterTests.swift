//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
@testable import StyleSyncCore
import Files

class StyleExporterTests: XCTestCase {
	// MARK: - Constants
	
	private enum Constant {
		static let fileWithReferencesToDeprecatedStylesName = "FileWithReferenceToDeprecatedStyles.fileExtension"
		static let fileWithReferencesToNewStylesOneName = "FileWithReferenceToNewOneStyles.fileExtension"
		static let fileWithReferencesToNewStylesOneAndTwoName = "FileWithReferenceToNewOneAndTwoStyles.fileExtension"
	}
	
	// MARK: - Stored variables
	
	private let projectFolder: Folder = testResources

	private let textStylesTemplate: File = try! testResources.file(named: "TextStylesTemplate.fileExtension-template.txt")
	private let colorStylesTemplate: File = try! testResources.file(named: "ColorStylesTemplate.fileExtension-template.txt")
	
	private let deprecatedColorStyle = ColorStyle(
		name: "Deprecated Color Style",
		identifier: "C0",
		color: .red,
		isDeprecated: true
	)
	private let newColorStyleOne = ColorStyle(
		name: "New Color Style 1",
		identifier: "C1",
		color: .green,
		isDeprecated: false
	)
	private let newColorStyleTwo = ColorStyle(
		name: "New Color Style 2",
		identifier: "C2",
		color: .green,
		isDeprecated: false
	)
	
	// MARK: - Computed variables
	
	private var generatedRawTextStylesFile: File {
		return try! projectFolder.createFileIfNeeded(withName: "generatedRawTextStylesFile.json")
	}
	private var generatedRawColorStylesFile: File {
		return try! projectFolder.createFileIfNeeded(withName: "generatedRawColorStylesFile.json")
	}
	
	private var renamedNewColorStyleOne: ColorStyle {
		return ColorStyle(
			name: "Renamed New Color Style",
			identifier: newColorStyleOne.identifier,
			color: newColorStyleOne.color,
			isDeprecated: false
		)
	}
	
	private var deprecatedTextStyle: TextStyle {
		return TextStyle(
			name: "Deprecated Text Style",
			identifier: "T0",
			fontName: "FontName",
			pointSize: 16,
			kerning: 0,
			lineHeight: 20,
			colorStyle: deprecatedColorStyle,
			isDeprecated: true
		)
	}
	private var newTextStyleOne: TextStyle {
		return TextStyle(
			name: "New Text Style 1",
			identifier: "T1",
			fontName: "DifferentFontName",
			pointSize: 18,
			kerning: 2,
			lineHeight: 16,
			colorStyle: newColorStyleOne,
			isDeprecated: false
		)
	}
	private var newTextStyleTwo: TextStyle {
		return TextStyle(
			name: "New Text Style 2",
			identifier: "T2",
			fontName: "DifferentFontName",
			pointSize: 20,
			kerning: 4,
			lineHeight: 18,
			colorStyle: newColorStyleTwo,
			isDeprecated: false
		)
	}
	private var renamedNewTextStyleOne: TextStyle {
		return TextStyle(
			name: "Renamed New Text Style",
			identifier: newTextStyleOne.identifier,
			fontName: newTextStyleOne.fontName,
			pointSize: newTextStyleOne.pointSize,
			kerning: newTextStyleOne.kerning,
			lineHeight: newTextStyleOne.lineHeight,
			colorStyle: newTextStyleOne.colorStyle,
			isDeprecated: false
		)
	}
	
	// MARK: - Overrides
	
	override func tearDown() {
		// Remove the raw style files.
		do {
			try generatedRawTextStylesFile.delete()
		} catch {
			print(error)
		}
		do {
			try generatedRawColorStylesFile.delete()
		} catch {
			print(error)
		}
		deleteFileWithReferencesToDeprecatedStyles()
		deleteFileWithReferencesToNewStyles()
		
		do {
			try testResources.file(named: "TextStylesTemplate.fileExtension").delete()
			try testResources.file(named: "ColorStylesTemplate.fileExtension").delete()
		} catch {
			print(error)
		}
		
		super.tearDown()
	}
	
	// MARK: - Tests
	
	func testWhenADeprecatedStyleIsUsedInTheProjectThenFileNamesForDeprecatedStyleNamesHasTheCorrectValues() {
		createFileWithReferencesToDeprecatedStyles()
		
		let styleExporter = getStylesExporterAndExportStyles(
			latestTextStyles: [newTextStyleOne],
			latestColorStyles: [newColorStyleOne],
			previouslyExportedTextStyles: [deprecatedTextStyle],
			previouslyExportedColorStyles: [deprecatedColorStyle]
		)
		
		let fileNamesForDeprecatedStyleNames = styleExporter.fileNamesForDeprecatedStyleNames
		XCTAssertEqual(fileNamesForDeprecatedStyleNames[deprecatedTextStyle.name]?.count, 1)
		XCTAssertEqual(fileNamesForDeprecatedStyleNames[deprecatedColorStyle.name]?.count, 1)
	}
	
	func testWhenADeprecatedStyleIsUsedInTheProjectThenNewStylesContainsDeprecatedStyles() {
		createFileWithReferencesToDeprecatedStyles()
		
		let styleExporter = getStylesExporterAndExportStyles(
			latestTextStyles: [newTextStyleOne],
			latestColorStyles: [newColorStyleOne],
			previouslyExportedTextStyles: [deprecatedTextStyle],
			previouslyExportedColorStyles: [deprecatedColorStyle]
		)
		
		let newDeprecatedTextStyles = styleExporter.newTextStyles.filter({ $0.isDeprecated })
		let newDeprecatedColorStyles = styleExporter.newColorStyles.filter({ $0.isDeprecated })
		
		XCTAssertEqual(newDeprecatedTextStyles.count, 1)
		XCTAssertEqual(newDeprecatedColorStyles.count, 1)
	}
	
	func testWhenOldStylesAreUsedInTheProjectThenNewStylesContainsThoseStylesAsDeprecatedStyles() {
		createFileWithReferencesToNewStylesOne()
		
		let styleExporter = getStylesExporterAndExportStyles(
			latestTextStyles: [],
			latestColorStyles: [],
			previouslyExportedTextStyles: [newTextStyleOne],
			previouslyExportedColorStyles: [newColorStyleOne]
		)
		
		let newDeprecatedTextStyles = styleExporter.newTextStyles.filter({ $0.isDeprecated })
		let newDeprecatedColorStyles = styleExporter.newColorStyles.filter({ $0.isDeprecated })
		
		XCTAssertEqual(newDeprecatedTextStyles.count, 1)
		XCTAssertEqual(newDeprecatedColorStyles.count, 1)
	}
	
	func testWhenADeprecatedStyleIsNotUsedInTheProjectThenNewStylesDoesNotContainDeprecatedStyles() {
		let styleExporter = getStylesExporterAndExportStyles(
			latestTextStyles: [newTextStyleOne],
			latestColorStyles: [newColorStyleOne],
			previouslyExportedTextStyles: [deprecatedTextStyle],
			previouslyExportedColorStyles: [deprecatedColorStyle]
		)
		
		let newDeprecatedTextStyles = styleExporter.newTextStyles.filter({ $0.isDeprecated })
		let newDeprecatedColorStyles = styleExporter.newColorStyles.filter({ $0.isDeprecated })
		
		XCTAssertEqual(newDeprecatedTextStyles.count, 0)
		XCTAssertEqual(newDeprecatedColorStyles.count, 0)
	}
	
	func testWhenAStyleIsRenamedThenTheReferencesAreUpdated() {
		createFileWithReferencesToNewStylesOne()
		
		let _ = getStylesExporterAndExportStyles(
			latestTextStyles: [renamedNewTextStyleOne],
			latestColorStyles: [renamedNewColorStyleOne],
			previouslyExportedTextStyles: [newTextStyleOne],
			previouslyExportedColorStyles: [newColorStyleOne]
		)
		
		let fileWithReferencesToNewStylesString: String
		do {
			let fileWithReferencesToNewStyles = try projectFolder.file(
				named: Constant.fileWithReferencesToNewStylesOneName
			)
			fileWithReferencesToNewStylesString = try fileWithReferencesToNewStyles.readAsString()
		} catch {
			return XCTFail(error.localizedDescription)
		}
		
		let expectedFileWithReferencesToNewStylesString = """
			\(renamedNewTextStyleOne.name.camelcased)
			\(renamedNewColorStyleOne.name.camelcased)
			"""
		XCTAssertEqual(fileWithReferencesToNewStylesString, expectedFileWithReferencesToNewStylesString)
	}
	
	func testWhenAStyleIsRenamedToAnExistingStylesNameThenTheReferencesAreUpdatedCorrectly() {
		createFileWithReferencesToNewStylesOneAndTwo()
		
		let newTextStyleOneWithNewTextStyleTwoName = TextStyle(
			name: newTextStyleTwo.name,
			identifier: newTextStyleOne.identifier,
			fontName: newTextStyleOne.fontName,
			pointSize: newTextStyleOne.pointSize,
			kerning: newTextStyleOne.kerning,
			lineHeight: newTextStyleOne.lineHeight,
			colorStyle: newTextStyleOne.colorStyle,
			isDeprecated: false
		)
		let renamedNewTextStyleTwo = TextStyle(
			name: "Renamed Text Style 2",
			identifier: newTextStyleTwo.identifier,
			fontName: newTextStyleTwo.fontName,
			pointSize: newTextStyleTwo.pointSize,
			kerning: newTextStyleTwo.kerning,
			lineHeight: newTextStyleTwo.lineHeight,
			colorStyle: newTextStyleTwo.colorStyle,
			isDeprecated: false
		)
		let newColorStyleOneWithNewColorStyleTwoName = ColorStyle(
			name: newColorStyleTwo.name,
			identifier: newColorStyleOne.identifier,
			color: newColorStyleOne.color,
			isDeprecated: newColorStyleOne.isDeprecated
		)
		let renamedNewColorStyleTwo = ColorStyle(
			name: "Renamed Color Style 2",
			identifier: newColorStyleTwo.identifier,
			color: newColorStyleTwo.color,
			isDeprecated: newColorStyleTwo.isDeprecated
		)
		
		let _ = getStylesExporterAndExportStyles(
			latestTextStyles: [newTextStyleOneWithNewTextStyleTwoName, renamedNewTextStyleTwo],
			latestColorStyles: [newColorStyleOneWithNewColorStyleTwoName, renamedNewColorStyleTwo],
			previouslyExportedTextStyles: [newTextStyleOne, newTextStyleTwo],
			previouslyExportedColorStyles: [newColorStyleOne, newColorStyleTwo]
		)
		
		let fileWithReferencesToNewStylesString: String
		do {
			let fileWithReferencesToNewStyles = try projectFolder.file(
				named: Constant.fileWithReferencesToNewStylesOneAndTwoName
			)
			fileWithReferencesToNewStylesString = try fileWithReferencesToNewStyles.readAsString()
		} catch {
			return XCTFail(error.localizedDescription)
		}
		
		let expectedFileWithReferencesToNewStylesString = """
		\(newTextStyleTwo.name.camelcased)
		\(newColorStyleTwo.name.camelcased)
		\(renamedNewTextStyleTwo.name.camelcased)
		\(renamedNewColorStyleTwo.name.camelcased)
		"""
		XCTAssertEqual(fileWithReferencesToNewStylesString, expectedFileWithReferencesToNewStylesString)
	}


	func testWhenNoStyleIsRenamedThenMutatedFilesIsEmpty() {
		createFileWithReferencesToNewStylesOne()
		
		let styleExporter = getStylesExporterAndExportStyles(
			latestTextStyles: [newTextStyleOne],
			latestColorStyles: [newColorStyleOne],
			previouslyExportedTextStyles: [newTextStyleOne],
			previouslyExportedColorStyles: [newColorStyleOne]
		)
		
		let expectedFiles: Set<File> = []
		XCTAssertEqual(styleExporter.mutatedFiles, expectedFiles)
	}
	
	func testWhenAStyleIsRenamedThenMutatedFilesContainsTheUpdatedFiles() {
		createFileWithReferencesToNewStylesOne()
		
		let styleExporter = getStylesExporterAndExportStyles(
			latestTextStyles: [renamedNewTextStyleOne],
			latestColorStyles: [renamedNewColorStyleOne],
			previouslyExportedTextStyles: [newTextStyleOne],
			previouslyExportedColorStyles: [newColorStyleOne]
		)
		
		let expectedFiles: Set<File>
		do {
			let fileWithReferencesToNewStyles = try projectFolder.file(
				named: Constant.fileWithReferencesToNewStylesOneName
			)
			expectedFiles = [fileWithReferencesToNewStyles]
		} catch {
			return XCTFail(error.localizedDescription)
		}

		XCTAssertEqual(styleExporter.mutatedFiles, expectedFiles)
	}
	
	func testNewStylesContainsAllTheLatestStyles() {
		let styleExporter = getStylesExporterAndExportStyles(
			latestTextStyles: [newTextStyleOne],
			latestColorStyles: [newColorStyleOne],
			previouslyExportedTextStyles: [],
			previouslyExportedColorStyles: []
		)
		
		XCTAssertEqual(styleExporter.newTextStyles.count, 1)
		XCTAssertEqual(styleExporter.newColorStyles.count, 1)
	}
	
	// MARK: - Helpers
	
	private func getStylesExporterAndExportStyles(
		latestTextStyles: [TextStyle],
		latestColorStyles: [ColorStyle],
		previouslyExportedTextStyles: [TextStyle],
		previouslyExportedColorStyles: [ColorStyle]
	) -> StyleExporter {
		let styleExporter = StyleExporter(
			latestTextStyles: latestTextStyles,
			latestColorStyles: latestColorStyles,
			previouslyExportedTextStyles: previouslyExportedTextStyles,
			previouslyExportedColorStyles: previouslyExportedColorStyles,
			projectFolder: projectFolder,
			textStyleTemplateFile: textStylesTemplate,
			colorStyleTemplateFile: colorStylesTemplate,
			exportTextFolder: projectFolder,
			exportColorsFolder: projectFolder,
			generatedRawTextStylesFile: generatedRawTextStylesFile,
			generatedRawColorStylesFile: generatedRawColorStylesFile,
			previousStylesVersion: .firstVersion
		)
		do {
			try styleExporter.exportStyles()
		} catch {
			XCTFailAndAbort(error.localizedDescription)
		}
		return styleExporter
	}
	
	private func createFileWithReferencesToDeprecatedStyles() {
		let stringWithReferenceToDeprecatedStyles = """
			\(deprecatedTextStyle.name.camelcased)
			\(deprecatedColorStyle.name.camelcased)
			"""
		do {
			try projectFolder.createFile(
				named: Constant.fileWithReferencesToDeprecatedStylesName,
				contents: stringWithReferenceToDeprecatedStyles
			)
		} catch {
			XCTFailAndAbort(error.localizedDescription)
		}
	}
	
	private func createFileWithReferencesToNewStylesOne() {
		let stringWithReferenceToNewStyles = """
		\(newTextStyleOne.name.camelcased)
		\(newColorStyleOne.name.camelcased)
		"""
		do {
			try projectFolder.createFile(
				named: Constant.fileWithReferencesToNewStylesOneName,
				contents: stringWithReferenceToNewStyles
			)
		} catch {
			XCTFailAndAbort(error.localizedDescription)
		}
	}
	
	private func createFileWithReferencesToNewStylesOneAndTwo() {
		let stringWithReferenceToNewStyles = """
		\(newTextStyleOne.name.camelcased)
		\(newColorStyleOne.name.camelcased)
		\(newTextStyleTwo.name.camelcased)
		\(newColorStyleTwo.name.camelcased)
		"""
		do {
			try projectFolder.createFile(
				named: Constant.fileWithReferencesToNewStylesOneAndTwoName,
				contents: stringWithReferenceToNewStyles
			)
		} catch {
			XCTFailAndAbort(error.localizedDescription)
		}
	}
	
	private func deleteFileWithReferencesToDeprecatedStyles() {
		do {
			try
				projectFolder
				.file(named: Constant.fileWithReferencesToDeprecatedStylesName)
				.delete()
		} catch {
			print(error.localizedDescription)
		}
	}
	
	private func deleteFileWithReferencesToNewStyles() {
		do {
			try
				projectFolder
					.file(named: Constant.fileWithReferencesToNewStylesOneName)
					.delete()
		} catch {
			print(error.localizedDescription)
		}
	}
}
