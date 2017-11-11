//
//  StyleExporter.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 08/11/2017.
//

import Foundation
import Files

final class StyleExporter {
	// MARK: - Constants
	
	private enum Constant {
		static let defaultColorStylesName = "ColorStyles"
		static let defaultTextStylesName = "TextStyles"
	}
	
	// MARK: - Stored variables
	
	private let latestTextStyles: [TextStyle]
	private let latestColorStyles: [ColorStyle]
	private let previouslyExportedTextStyles: [TextStyle]
	private let previouslyExportedColorStyles: [ColorStyle]
	
	var oldTextStyles: [CodeTemplateReplacableStyle] = []
	var oldColorStyles: [CodeTemplateReplacableStyle] = []
	var newTextStyles: [CodeTemplateReplacableStyle] = []
	var newColorStyles: [CodeTemplateReplacableStyle] = []
	
	private let projectFolder: Folder
	private let textStyleTemplateFile: File
	private let colorStyleTemplateFile: File
	private let exportTextFolder: Folder
	private let exportColorsFolder: Folder
	private let generatedRawTextStylesFile: File
	private let generatedRawColorStylesFile: File
	
	private var filesForDeprecatedColorStyle: [CodeTemplateReplacableStyle: [File]] = [:]
	private var filesForDeprecatedTextStyle: [CodeTemplateReplacableStyle: [File]] = [:]
	
	var generatedTextStylesFile: File!
	var generatedColorStylesFile: File!
	
	private let previousStylesVersion: Version?
	var version: Version!
	
	// MARK: - Computed variables
	
	private var usedDeprecatedColorStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedColorStyle.keys)
	}
	private var usedDeprecatedTextStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedTextStyle.keys)
	}
	
	var fileNamesForDeprecatedStyleNames: [String: [String]] {
		var fileNamesForDeprecatedStyleNames: [String: [String]] = [:]
		Array(filesForDeprecatedColorStyle.keys)
			.forEach { style in
				let filesForStyle = filesForDeprecatedColorStyle[style]
				let fileNames: [String] = filesForStyle?.map({ $0.name }) ?? []
				fileNamesForDeprecatedStyleNames[style.name] = fileNames
		}
		Array(filesForDeprecatedTextStyle.keys)
			.forEach { style in
				let filesForStyle = filesForDeprecatedTextStyle[style]
				let fileNames: [String] = filesForStyle?.map({ $0.name }) ?? []
				fileNamesForDeprecatedStyleNames[style.name] = fileNames
		}
		return fileNamesForDeprecatedStyleNames
	}
	
	// MARK: - Initializer
	
	init(
		latestTextStyles: [TextStyle],
		latestColorStyles: [ColorStyle],
		previouslyExportedTextStyles: [TextStyle],
		previouslyExportedColorStyles: [ColorStyle],
		projectFolder: Folder,
		textStyleTemplateFile: File,
		colorStyleTemplateFile: File,
		exportTextFolder: Folder,
		exportColorsFolder: Folder,
		generatedRawTextStylesFile: File,
		generatedRawColorStylesFile: File,
		previousStylesVersion: Version?
	) {
		self.latestTextStyles = latestTextStyles
		self.latestColorStyles = latestColorStyles
		self.previouslyExportedTextStyles = previouslyExportedTextStyles
		self.previouslyExportedColorStyles = previouslyExportedColorStyles
		self.projectFolder = projectFolder
		self.textStyleTemplateFile = textStyleTemplateFile
		self.colorStyleTemplateFile = colorStyleTemplateFile
		self.exportTextFolder = exportTextFolder
		self.exportColorsFolder = exportColorsFolder
		self.generatedRawTextStylesFile = generatedRawTextStylesFile
		self.generatedRawColorStylesFile = generatedRawColorStylesFile
		self.previousStylesVersion = previousStylesVersion
	}
	
	// MARK: - Actions
	
	func exportStyles() throws {
		let (textStyleParser, colorStyleParser) = createStyleParsers(
			latestTextStyles: latestTextStyles,
			latestColorStyles: latestColorStyles
		)
		
		let currentAndMigratedTextStyles = textStyleParser
			.getCurrentAndMigratedStyles(usingPreviouslyExportedStyles: previouslyExportedTextStyles)
		let currentAndMigratedColorStyles = colorStyleParser
			.getCurrentAndMigratedStyles(usingPreviouslyExportedStyles: previouslyExportedColorStyles)
		let deprecatedTextStyles = textStyleParser
			.deprecatedStyles(usingPreviouslyExportedStyles: previouslyExportedTextStyles)
		let deprecatedColorStyles = colorStyleParser
			.deprecatedStyles(usingPreviouslyExportedStyles: previouslyExportedColorStyles)
		
		let (textStyleCodeGenerator, colorStyleCodeGenerator) = try createStyleCodeGenerators(
			textStyleTemplateFile: textStyleTemplateFile,
			colorStyleTemplateFile: colorStyleTemplateFile
		)
		
		let textStylesFileExtension = textStyleCodeGenerator.fileExtension
		let colorStylesFileExtension = colorStyleCodeGenerator.fileExtension
		
		generatedTextStylesFile = try exportTextFolder.createFileIfNeeded(
			named: textStyleCodeGenerator.fileName ?? Constant.defaultTextStylesName,
			fileExtension: textStylesFileExtension
		)
		generatedColorStylesFile = try exportColorsFolder.createFileIfNeeded(
			named: colorStyleCodeGenerator.fileName ?? Constant.defaultColorStylesName,
			fileExtension: colorStylesFileExtension
		)
		
		let (newColorStyles, newTextStyles) = processStyles(
			deprecatedTextStyles: deprecatedTextStyles,
			deprecatedColorStyles: deprecatedColorStyles,
			latestTextStyles: latestTextStyles,
			latestColorStyles: latestColorStyles,
			textStylesFileExtension: textStylesFileExtension,
			colorStylesFileExtension: colorStylesFileExtension
		)
		self.newColorStyles = newColorStyles
		self.newTextStyles = newTextStyles
		
		print("Updating references to styles in your project")
		let ignoredFiles: [File] = [
			generatedColorStylesFile,
			generatedTextStylesFile
		]
		
		try updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles(
			textStylesFileExtension: textStylesFileExtension,
			colorStylesFileExtension: colorStylesFileExtension,
			currentAndMigratedTextStyles: currentAndMigratedTextStyles,
			currentAndMigratedColorStyles: currentAndMigratedColorStyles,
			deprecatedTextStyles: deprecatedTextStyles,
			deprecatedColorStyles: deprecatedColorStyles,
			ignoredFiles: ignoredFiles
		)
		
		oldColorStyles = previouslyExportedColorStyles.map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		oldTextStyles = previouslyExportedTextStyles.map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		
		updateVersion()
		
		print("Generating styling code")
		try generateAndSaveStyleCode(
			version: version,
			colorStyles: newColorStyles,
			textStyles: newTextStyles,
			textStylesCodeGenerator: textStyleCodeGenerator,
			colorStylesCodeGenerator: colorStyleCodeGenerator
		)
		try generateAndSaveVersionedStyles(
			version: version,
			colorStyles: newColorStyles.map({ $0.style as? ColorStyle }).flatMap({$0}),
			textStyles: newTextStyles.map({ $0.style as? TextStyle }).flatMap({$0}),
			generatedRawTextStylesFile: generatedRawTextStylesFile,
			generatedRawColorStylesFile: generatedRawColorStylesFile
		)
		
		try printUpdatedStyles()
		print("🎉  Your styles are now up to date!")
	}
	
	private func createStyleParsers(latestTextStyles: [TextStyle], latestColorStyles: [ColorStyle]) -> (text: StyleParser<TextStyle>, color: StyleParser<ColorStyle>) {
		let textStyleParser = StyleParser(newStyles: latestTextStyles)
		let colorStyleParser = StyleParser(newStyles: latestColorStyles)
		return (textStyleParser, colorStyleParser)
	}
	
	/// Removes unused deprecated styles from project files and creates two
	/// arrays of styles ready to be exported.
	///
	/// - Parameters:
	///   - deprecatedTextStyles: Deprecated text styles
	///   - deprecatedColorStyles: Deprecated text styles
	///   - latestTextStyles: The latest text styles
	///   - latestColorStyles: The latest color styles
	/// - Returns: Arrays of the latest and deprecated styles.
	
	// TODO: Update docs
	private func processStyles(
		deprecatedTextStyles: [TextStyle],
		deprecatedColorStyles: [ColorStyle],
		latestTextStyles: [TextStyle],
		latestColorStyles: [ColorStyle],
		textStylesFileExtension: String,
		colorStylesFileExtension: String
	) -> (colorStyles: [CodeTemplateReplacableStyle], textStyles: [CodeTemplateReplacableStyle]) {
		var deprecatedReplacableTextStyles = deprecatedTextStyles
			.map({ CodeTemplateReplacableStyle(textStyle: $0, fileType: textStylesFileExtension) })
		var deprecatedReplacableColorStyles = deprecatedColorStyles
			.map({ CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStylesFileExtension) })
		let latestReplacableTextStyles = latestTextStyles
			.map({ CodeTemplateReplacableStyle(textStyle: $0, fileType: textStylesFileExtension) })
		let latestReplacableColorStyles = latestColorStyles
			.map({ CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStylesFileExtension) })
		
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedReplacableColorStyles,
			usedDeprecatedStyles: usedDeprecatedColorStyles,
			newStyles: latestReplacableColorStyles
		)
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedReplacableTextStyles,
			usedDeprecatedStyles: usedDeprecatedTextStyles,
			newStyles: latestReplacableTextStyles
		)
		
		let allColorStyles = latestReplacableColorStyles + deprecatedReplacableColorStyles
		let allTextStyles = latestReplacableTextStyles + deprecatedReplacableTextStyles
		
		return (allColorStyles, allTextStyles)
	}
	
	private func createStyleCodeGenerators(
		textStyleTemplateFile: File,
		colorStyleTemplateFile: File
		) throws -> (text: CodeGenerator, color: CodeGenerator) {
		let colorStyleTemplate: Template = try colorStyleTemplateFile.readAsString()
		let textStyleTemplate: Template = try textStyleTemplateFile.readAsString()
		
		let textStyleCodeGenerator = try CodeGenerator(template: textStyleTemplate)
		let colorStyleCodeGenerator = try CodeGenerator(template: colorStyleTemplate)
		return (textStyleCodeGenerator, colorStyleCodeGenerator)
	}
	
	private func updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles(
		textStylesFileExtension: String,
		colorStylesFileExtension: String,
		currentAndMigratedTextStyles: [(TextStyle, TextStyle)],
		currentAndMigratedColorStyles: [(ColorStyle, ColorStyle)],
		deprecatedTextStyles: [TextStyle],
		deprecatedColorStyles: [ColorStyle],
		ignoredFiles: [File]
		) throws {
		let supportedFileTypes: Set<FileType> = [
			textStylesFileExtension,
			colorStylesFileExtension
		]
		
		// Update style references.
		let currentAndMigratedTextReplacableStyles = currentAndMigratedTextStyles
			.map({ currentAndMigratedTextStyle -> (CodeTemplateReplacableStyle, CodeTemplateReplacableStyle) in
				let fileType = textStylesFileExtension
				let currentStyle = CodeTemplateReplacableStyle(textStyle: currentAndMigratedTextStyle.0, fileType: fileType)
				let migratedStyle = CodeTemplateReplacableStyle(textStyle: currentAndMigratedTextStyle.1, fileType: fileType)
				return (currentStyle, migratedStyle)
			})
		let currentAndMigratedColorReplacableStyles = currentAndMigratedColorStyles
			.map({ currentAndMigratedColorStyle -> (CodeTemplateReplacableStyle, CodeTemplateReplacableStyle) in
				let fileType = colorStylesFileExtension
				let currentStyle = CodeTemplateReplacableStyle(colorStyle: currentAndMigratedColorStyle.0, fileType: fileType)
				let migratedStyle = CodeTemplateReplacableStyle(colorStyle: currentAndMigratedColorStyle.1, fileType: fileType)
				return (currentStyle, migratedStyle)
			})
		
		let updateOldColorStyleReferencesOperation = updateOldReferencesFileOperation(
			currentAndMigratedStyles: currentAndMigratedColorReplacableStyles
		)
		let updateOldTextStyleReferencesOperation = updateOldReferencesFileOperation(
			currentAndMigratedStyles: currentAndMigratedTextReplacableStyles
		)
		
		// Find used deprecated styles.
		let deprecatedTextStyles = deprecatedTextStyles
			.map({ CodeTemplateReplacableStyle(textStyle: $0, fileType: textStylesFileExtension) })
		let deprecatedColorStyles = deprecatedColorStyles
			.map({ CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStylesFileExtension) })
		
		let findUsedDeprecatedColorStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: deprecatedColorStyles,
			filesForDeprecatedStyle: &filesForDeprecatedColorStyle
		)
		let findUsedDeprecatedTextStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: deprecatedTextStyles,
			filesForDeprecatedStyle: &filesForDeprecatedTextStyle
		)
		
		let allOperations: [FileOperation] = [
			updateOldColorStyleReferencesOperation,
			updateOldTextStyleReferencesOperation,
			findUsedDeprecatedColorStylesOperation,
			findUsedDeprecatedTextStylesOperation
		]
		
		projectFolder
			.makeSubfolderSequence(recursive: true, includeHidden: false)
			.forEach { folder in
				folder
					.makeFileSequence(recursive: true, includeHidden: false)
					.filter({ supportedFileTypes.contains($0.extension ?? "") })
					.filter({ !ignoredFiles.contains($0) })
					.forEach({ file in
						allOperations.forEach(({ $0(file) }))
					})
		}
	}
	
	private func updateVersion() {
		version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: newColorStyles,
			newTextStyles: newTextStyles,
			previousStylesVersion: previousStylesVersion
		)
	}
	
	private func generateAndSaveStyleCode(
		version: Version,
		colorStyles: [CodeTemplateReplacableStyle],
		textStyles: [CodeTemplateReplacableStyle],
		textStylesCodeGenerator: CodeGenerator,
		colorStylesCodeGenerator: CodeGenerator
	) throws {
		let generatedTextStylesCode = textStylesCodeGenerator
			.generatedCode(for: [textStyles], version: version)
		let generatedColorStylesCode = colorStylesCodeGenerator
			.generatedCode(for: [colorStyles], version: version)
		
		try generatedColorStylesFile.write(string: generatedColorStylesCode)
		try generatedTextStylesFile.write(string: generatedTextStylesCode)
	}
	
	private func generateAndSaveVersionedStyles(
		version: Version,
		colorStyles: [ColorStyle],
		textStyles: [TextStyle],
		generatedRawTextStylesFile: File,
		generatedRawColorStylesFile: File
	) throws {
		let versionedTextStyles = VersionedStyle.Text(version: version, textStyles: textStyles)
		let versionedColorStyles = VersionedStyle.Color(version: version, colorStyles: colorStyles)
		
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let rawTextStylesData = try encoder.encode(versionedTextStyles)
		let rawColorStylesData = try encoder.encode(versionedColorStyles)
		
		try generatedRawTextStylesFile.write(data: rawTextStylesData)
		try generatedRawColorStylesFile.write(data: rawColorStylesData)
	}
	
	private func printUpdatedStyles() {
		let consoleLogGenerator: StyleUpdateSummaryGenerator
		do {
			consoleLogGenerator = try StyleUpdateSummaryGenerator(
				headingTemplate: ConsoleTemplate.heading,
				styleNameTemplate: ConsoleTemplate.styleName,
				addedStyleTableTemplate: ConsoleTemplate.newStyleTable,
				updatedStyleTableTemplate: ConsoleTemplate.updatedStylesTable,
				deprecatedStylesTableTemplate: ConsoleTemplate.deprecatedStylesTable,
				shouldPrintStyleSyncLink: false
			)
		} catch {
			ErrorManager.log(error: error, context: .printStyles)
			return
		}

		let consoleLog = consoleLogGenerator.body(
			fromOldColorStyles: oldColorStyles,
			newColorStyles: newColorStyles,
			oldTextStyles: oldTextStyles,
			newTextStyles: newTextStyles,
			fileNamesForDeprecatedStyleNames: fileNamesForDeprecatedStyleNames
		)
		print(consoleLog)
	}
	
	// MARK: - Helpers
	
	private func updateOldReferencesFileOperation(
		currentAndMigratedStyles: [(CodeTemplateReplacableStyle, CodeTemplateReplacableStyle)]
	) -> FileOperation {
		return { file in
			var fileString: String
			do {
				fileString = try file.readAsString()
			} catch {
				ErrorManager.log(error: error, context: .projectReferenceUpdate)
				return
			}
			currentAndMigratedStyles.forEach({
				fileString = fileString.replacingOccurrences(of: $0.0.variableName, with: $0.1.variableName)
			})
			
			do {
				try file.write(string: fileString)
			} catch {
				ErrorManager.log(error: error, context: .projectReferenceUpdate)
			}
		}
	}
	
	private func findUsedDeprecatedStylesFileOperation(
		deprecatedStyles: [CodeTemplateReplacableStyle],
		filesForDeprecatedStyle: inout [CodeTemplateReplacableStyle: [File]]
	) -> FileOperation {
		return { file in
			var fileString: String
			do {
				fileString = try file.readAsString()
			} catch {
				ErrorManager.log(error: error, context: .projectReferenceUpdate)
				return
			}
			
			deprecatedStyles
				.filter({ fileString.contains($0.variableName) })
				.forEach({ style in
					var filesForStyle = filesForDeprecatedStyle[style] ?? []
					guard !filesForStyle.contains(file) else {
						return
					}
					filesForStyle.append(file)
					filesForDeprecatedStyle[style] = filesForStyle
				})
		}
	}
	
	private func removeUnusedDeprecatedStyles(
		deprecatedStyles: inout [CodeTemplateReplacableStyle],
		usedDeprecatedStyles: [CodeTemplateReplacableStyle],
		newStyles: [CodeTemplateReplacableStyle]
	) {
		// Only styles that are still in the project should be deprecated, and
		// any others removed completely.
		deprecatedStyles = deprecatedStyles
			.filter({ return usedDeprecatedStyles.contains($0) })
			.filter({ style -> Bool in
				// If a style is removed but another is added with the same
				// name, then remove the deprecated one to avoid compilation
				// issues.
				if newStyles.contains(where: { return $0.variableName == style.variableName }) {
					print("⚠️  Style with name \(style.variableName) was removed and added again with a different name.")
					return false
				} else {
					return true
				}
			})
	}
}
