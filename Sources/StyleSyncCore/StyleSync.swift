//
//  StyleSync.swift
//  StyleSync
//
//  Created by Dylan Lewis on 09/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa
import Files
import ShellOut

public final class StyleSync {
	// MARK: - Constants
	
	private enum Constant {
		static let exportedTextStylesFileName = "exportedTextStyles"
		static let exportedColorStylesFileName = "exportedColorStyles"
		static let exportedStylesFileType: FileType = .json
		static let defaultColorStylesName = "ColorStyles"
		static let defaultTextStylesName = "TextStyles"
	}
	
	// MARK: - Stored variables

	private var config: Config!
	
	private var filesForDeprecatedColorStyle: [CodeTemplateReplacableStyle: [File]] = [:]
	private var filesForDeprecatedTextStyle: [CodeTemplateReplacableStyle: [File]] = [:]

	private let projectFolder: Folder = .current
	
	// MARK: - Computed variables

	private var usedDeprecatedColorStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedColorStyle.keys)
	}
	private var usedDeprecatedTextStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedTextStyle.keys)
	}
	
	// MARK: - Initializer
	
	public init(arguments: [String] = CommandLine.arguments) throws {
		#if os(Linux)
			print("StyleSync does not support Linux")
			exit(1)
		#endif
		guard arguments.count == 1 else {
			throw Error.invalidArguments
		}
		let configManager = ConfigManager(projectFolder: projectFolder)
		self.config = try configManager.getConfig()
	}
	
	// MARK: - Run
	
	public func run() throws {
		let sketchDocumentFile: File
		let exportTextFolder: Folder
		let exportColorsFolder: Folder
		let textStyleTemplateFile: File
		let colorStyleTemplateFile: File
		do {
			sketchDocumentFile = try File(path: config.sketchDocument)
			exportTextFolder = try Folder(path: config.textStyle.exportDirectory)
			exportColorsFolder = try Folder(path: config.colorStyle.exportDirectory)
			textStyleTemplateFile = try File(path: config.textStyle.template)
			colorStyleTemplateFile = try File(path: config.colorStyle.template)
		} catch {
			ErrorManager.log(fatalError: error, context: .config)
		}
		
		try run(
			sketchDocumentFile: sketchDocumentFile,
			exportTextFolder: exportTextFolder,
			exportColorsFolder: exportColorsFolder,
			textStyleTemplateFile: textStyleTemplateFile,
			colorStyleTemplateFile: colorStyleTemplateFile,
			gitHubPersonalAccessToken: config.gitHubPersonalAccessToken
		)
	}
	
	public func run(
		sketchDocumentFile: File,
		exportTextFolder: Folder,
		exportColorsFolder: Folder,
		textStyleTemplateFile: File,
		colorStyleTemplateFile: File,
		gitHubPersonalAccessToken: String?
	) throws {
		let sketchManager = SketchManager(sketchFile: sketchDocumentFile)
		let sketchDocument: SketchDocument
		do {
			sketchDocument = try sketchManager.getSketchDocument()
		} catch {
			ErrorManager.log(fatalError: error, context: .sketch)
		}
		
		let generatedRawTextStylesFile = try exportTextFolder.createFileIfNeeded(
			named: Constant.exportedTextStylesFileName,
			fileExtension: Constant.exportedStylesFileType
		)
		let generatedRawColorStylesFile = try exportColorsFolder.createFileIfNeeded(
			named: Constant.exportedColorStylesFileName,
			fileExtension: Constant.exportedStylesFileType
		)
			
		let styleExtractor = StyleExtractor(
			generatedRawTextStylesFile: generatedRawTextStylesFile,
			generatedRawColorStylesFile: generatedRawColorStylesFile,
			sketchDocument: sketchDocument
		)
	
		let previouslyExportedTextStyles = styleExtractor.previouslyExportedTextStyles ?? []
		let previouslyExportedColorStyles = styleExtractor.previouslyExportedColorStyles ?? []
		let previousStylesVersion = styleExtractor.previousStylesVersion
		
		let latestTextStyles = styleExtractor.latestTextStyles
		let latestColorStyles = styleExtractor.latestColorStyles
	
		guard !(latestTextStyles.isEmpty || latestColorStyles.isEmpty) else {
			ErrorManager.log(fatalError: Error.noStylesFound, context: .styleExtraction)
		}
		
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

		let generatedTextStylesFile = try exportTextFolder.createFileIfNeeded(
			named: textStyleCodeGenerator.fileName ?? Constant.defaultTextStylesName,
			fileExtension: textStylesFileExtension
		)
		let generatedColorStylesFile = try exportColorsFolder.createFileIfNeeded(
			named: colorStyleCodeGenerator.fileName ?? Constant.defaultColorStylesName,
			fileExtension: colorStylesFileExtension
		)
		
		let (colorStyles, textStyles) = processStyles(
			deprecatedTextStyles: deprecatedTextStyles,
			deprecatedColorStyles: deprecatedColorStyles,
			latestTextStyles: latestTextStyles,
			latestColorStyles: latestColorStyles,
			textStylesFileExtension: textStylesFileExtension,
			colorStylesFileExtension: colorStylesFileExtension
		)
		
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
		
		let oldColorStyles = previouslyExportedColorStyles.map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		let oldTextStyles = previouslyExportedTextStyles.map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: colorStyles,
			newTextStyles: textStyles,
			previousStylesVersion: previousStylesVersion
		)
		
		print("Generating styling code")
		try generateAndSaveStyleCode(
			version: version,
			colorStyles: colorStyles,
			textStyles: textStyles,
			textStylesCodeGenerator: textStyleCodeGenerator,
			colorStylesCodeGenerator: colorStyleCodeGenerator,
			generatedTextStylesFile: generatedTextStylesFile,
			generatedColorStylesFile: generatedColorStylesFile
		)
		try generateAndSaveVersionedStyles(
			version: version,
			colorStyles: colorStyles.map({ $0.style as? ColorStyle }).flatMap({$0}),
			textStyles: textStyles.map({ $0.style as? TextStyle }).flatMap({$0}),
			generatedRawTextStylesFile: generatedRawTextStylesFile,
			generatedRawColorStylesFile: generatedRawColorStylesFile
		)
		
		try printUpdatedStyles(
			oldColorStyles: oldColorStyles,
			newColorStyles: colorStyles,
			oldTextStyles: oldTextStyles,
			newTextStyles: textStyles
		)
		print("🎉 Your styles are now up to date!")
		
		guard let gitHubPersonalAccessToken = gitHubPersonalAccessToken else {
			print("\nIf you'd like to branch, commit and raise a pull request for these updates, add your GitHub Personal Access token to styleSyncConfig.json")
			return
		}

		let filesToCommit = [
			generatedTextStylesFile,
			generatedColorStylesFile,
			generatedRawTextStylesFile,
			generatedRawColorStylesFile
		]
		do {
			let gitHubManager = try GitHubManager(
				projectFolder: projectFolder,
				fileNamesForDeprecatedStyleNames: fileNamesForDeprecatedStyleNames,
				version: version,
				personalAccessToken: gitHubPersonalAccessToken
			)
			try gitHubManager.createBranchAndCommitChangesAndSubmitPullRequest(
				filesToCommit: filesToCommit,
				oldTextStyles: oldTextStyles,
				newTextStyles: textStyles,
				oldColorStyles: oldColorStyles,
				newColorStyles: colorStyles
			)
		} catch {
			ErrorManager.log(fatalError: error, context: .gitHub)
		}
	}
	
	// MARK: - Actions
	
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
	
	private func generateAndSaveStyleCode(
		version: Version,
		colorStyles: [CodeTemplateReplacableStyle],
		textStyles: [CodeTemplateReplacableStyle],
		textStylesCodeGenerator: CodeGenerator,
		colorStylesCodeGenerator: CodeGenerator,
		generatedTextStylesFile: File,
		generatedColorStylesFile: File
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
	
	private func printUpdatedStyles(
		oldColorStyles: [CodeTemplateReplacableStyle],
		newColorStyles: [CodeTemplateReplacableStyle],
		oldTextStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle]
	) throws {
		let consoleLogGenerator = try StyleUpdateSummaryGenerator(
			headingTemplate: ConsoleTemplate.heading,
			styleNameTemplate: ConsoleTemplate.styleName,
			addedStyleTableTemplate: ConsoleTemplate.newStyleTable,
			updatedStyleTableTemplate: ConsoleTemplate.updatedStylesTable,
			deprecatedStylesTableTemplate: ConsoleTemplate.deprecatedStylesTable,
			shouldPrintStyleSyncLink: false
		)
		
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
	
	private func updateOldReferencesFileOperation(currentAndMigratedStyles: [(CodeTemplateReplacableStyle, CodeTemplateReplacableStyle)]) -> FileOperation {
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
	
	private func removeUnusedDeprecatedStyles(deprecatedStyles: inout [CodeTemplateReplacableStyle], usedDeprecatedStyles: [CodeTemplateReplacableStyle], newStyles: [CodeTemplateReplacableStyle]) {
		// Only styles that are still in the project should be deprecated, and
		// any others removed completely.
		deprecatedStyles = deprecatedStyles
			.filter({ return usedDeprecatedStyles.contains($0) })
			.filter({ style -> Bool in
				// If a style is removed but another is added with the same
				// name, then remove the deprecated one to avoid compilation
				// issues.
				if newStyles.contains(where: { return $0.variableName == style.variableName }) {
					print("⚠️ Style with name \(style.variableName) was removed and added again with a different name.")
					return false
				} else {
					return true
				}
			})
	}
	
	private var fileNamesForDeprecatedStyleNames: [String: [String]] {
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
}

extension StyleSync {
	enum Error: Swift.Error {
		case invalidArguments
		case noStylesFound
	}
}
