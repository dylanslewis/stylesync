//
//  StyleSync.swift
//  StyleSync
//
//  Created by Dylan Lewis on 09/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa
import Files

public final class StyleSync {
	// MARK: - Constants
	
	private enum Constant {
		static let expectedNumberOfArguments = 9
		static let exportedStylesFileName = "ExportedStyles"
		static let exportedStylesFileType: FileType = .json
		static let colorStylesName = "ColorStyles"
		static let textStylesName = "TextStyles"
	}
	
	// MARK: - Stored properties
	
	private var colorStyleParser: StyleParser<ColorStyle>!
	private var textStyleParser: StyleParser<TextStyle>!
	private var colorStyleCodeGenerator: CodeGenerator!
	private var textStyleCodeGenerator: CodeGenerator!
	private var filesForDeprecatedColorStyle: [CodeTemplateReplacableStyle: [File]] = [:]
	private var filesForDeprecatedTextStyle: [CodeTemplateReplacableStyle: [File]] = [:]

	private var projectFolder: Folder!
	private var exportFolder: Folder!

	private var sketchFile: File!
	private var colorStyleTemplate: File!
	private var textStyleTemplate: File!
	
	private var gitHubUsername: String!
	private var gitHubRepositoryName: String!
	private var gitHubPersonalAccessToken: String!
	
	private var zipManager: ZipManager!
	
	private var pullRequestHeadingTemplate: File!
	private var pullRequestStyleNameTemplate: File!
	private var pullRequestAddedStyleTableTemplate: File!
	private var pullRequestUpdatedStyleTableTemplate: File!
	private var pullRequestDeprecatedStylesTemplate: File!

	private var consoleHeadingTemplate: File!
	private var consoleStyleNameTemplate: File!
	private var consoleAddedStyleTableTemplate: File!
	private var consoleUpdatedStyleTableTemplate: File!
	private var consoleDeprecatedStylesTemplate: File!
	
	private var generatedColorStylesFile: File!
	private var generatedTextStylesFile: File!
	private var generatedRawStylesFile: File!
	
	// MARK: - Computed properties

	private var usedDeprecatedColorStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedColorStyle.keys)
	}
	private var usedDeprecatedTextStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedTextStyle.keys)
	}
	
	// MARK: - Initializer
	
	public init(arguments: [String] = CommandLine.arguments) throws {
		guard arguments.count == Constant.expectedNumberOfArguments else {
			throw Error.invalidArguments
		}
		try parse(arguments: arguments)
		try createZipManager(forSketchFile: sketchFile)
		try createGitHubTemplateReferences()
		try createConsoleTemplateReferences()
	}
	
	private func parse(arguments: [String]) throws {
		self.sketchFile = try File(path: arguments[1])
		self.projectFolder = try Folder(path: arguments[2])
		self.exportFolder = try Folder(path: arguments[3])
		self.colorStyleTemplate = try File(path: arguments[4])
		self.textStyleTemplate = try File(path: arguments[5])
		self.gitHubUsername = arguments[6]
		self.gitHubRepositoryName = arguments[7]
		self.gitHubPersonalAccessToken = arguments[8]
	}
	
	private func createZipManager(forSketchFile file: File) throws {
		self.zipManager = try ZipManager(zippedFile: file)
	}
	
	private func createGitHubTemplateReferences() throws {
		let gitHubTemplatesBaseURL = try Folder.current.subfolder(atPath: "Sources/StyleSyncCore/Templates/GitHub")
		self.pullRequestHeadingTemplate = try gitHubTemplatesBaseURL.file(named: "Heading")
		self.pullRequestStyleNameTemplate = try gitHubTemplatesBaseURL.file(named: "StyleName")
		self.pullRequestAddedStyleTableTemplate = try gitHubTemplatesBaseURL.file(named: "NewStyleTable")
		self.pullRequestUpdatedStyleTableTemplate = try gitHubTemplatesBaseURL.file(named: "UpdatedStyleTable")
		self.pullRequestDeprecatedStylesTemplate = try gitHubTemplatesBaseURL.file(named: "DeprecatedStylesTable")
	}
	
	private func createConsoleTemplateReferences() throws {
		let consoleTemplatesBaseURL = try Folder.current.subfolder(atPath: "Sources/StyleSyncCore/Templates/Console")
		self.consoleHeadingTemplate = try consoleTemplatesBaseURL.file(named: "Heading")
		self.consoleStyleNameTemplate = try consoleTemplatesBaseURL.file(named: "StyleName")
		self.consoleAddedStyleTableTemplate = try consoleTemplatesBaseURL.file(named: "NewStyleTable")
		self.consoleUpdatedStyleTableTemplate = try consoleTemplatesBaseURL.file(named: "UpdatedStyleTable")
		self.consoleDeprecatedStylesTemplate = try consoleTemplatesBaseURL.file(named: "DeprecatedStylesTable")
	}

	// MARK: - Run

	public func run() throws {
		let config = Config()
		let didFinishQuestionaire: (Creatable) -> Void = { completedConfig in
			print(completedConfig)
		}
		let questionaire = Questionaire(creatable: config, didFinishQuestionaire: didFinishQuestionaire)
		questionaire.startQuestionaire()
		return
		
		defer {
			do {
				try zipManager.cleanup()
			} catch {
				print(error)
			}
		}
		
		let sketchDocumentFile = try zipManager.getSketchDocument()
		let sketchDocument: SketchDocument = try sketchDocumentFile.readAsDecodedJSON()
		
		let previousExportedStyles = try getPreviousExportedStyles()
		createStyleParsers(using: sketchDocument, previousExportedStyles: previousExportedStyles)
		try createStyleCodeGenerators()
		try updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles()
		
		let oldColorStyles = (previousExportedStyles?.colorStyles ?? []).map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		let oldTextStyles = (previousExportedStyles?.textStyles ?? []).map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		
		let (colorStyles, textStyles) = getAllStyles()
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: colorStyles,
			newTextStyles: textStyles,
			currentVersion: previousExportedStyles?.version
		)
		
		guard previousExportedStyles?.version == nil || version != previousExportedStyles?.version else {
			print("🎉 Your styles are already up to date!")
			return
		}

		try generateAndSaveStyleCode(version: version, colorStyles: colorStyles, textStyles: textStyles)
		try generateAndSaveVersionedStyles(
			version: version,
			colorStyles: colorStyles.map({ $0.style as? ColorStyle }).flatMap({$0}),
			textStyles: textStyles.map({ $0.style as? TextStyle }).flatMap({$0})
		)

//		let (headBranchName, baseBranchName) = try createBranchAndCommitChanges(version: version)
//		try generateScreenshots()
		
//		try submitPullRequest(
//			headBranchName: headBranchName,
//			baseBranchName: baseBranchName,
//		oldColorStyles: oldColorStyles,
//		newColorStyles: colorStyles,
//		oldTextStyles: oldColorStyles,
//		newTextStyles: textStyles
//			version: version
//		)
		try printUpdatedStyles(
			oldColorStyles: oldColorStyles,
			newColorStyles: colorStyles,
			oldTextStyles: oldTextStyles,
			newTextStyles: textStyles
		)
	}
	
	// MARK: - Actions
	
	private func getPreviousExportedStyles() throws -> VersionedStyles? {
		generatedRawStylesFile = try exportFolder.createFileIfNeeded(
			named: Constant.exportedStylesFileName,
			fileExtension: Constant.exportedStylesFileType
		)
		
		do {
			return try generatedRawStylesFile.readAsDecodedJSON()
		} catch {
			return nil
		}
	}
	
	private func createStyleParsers(using sketchDocument: SketchDocument, previousExportedStyles: VersionedStyles?) {
		colorStyleParser = StyleParser(
			sketchDocument: sketchDocument,
			previousStyles: previousExportedStyles?.colorStyles
		)
		textStyleParser = StyleParser(
			sketchDocument: sketchDocument,
			colorStyles: colorStyleParser.newStyles,
			previousStyles: previousExportedStyles?.textStyles
		)
	}
	
	private func createStyleCodeGenerators() throws {
		let colorStyleTemplate: Template = try self.colorStyleTemplate.readAsString()
		let textStyleTemplate: Template = try self.textStyleTemplate.readAsString()
		
		colorStyleCodeGenerator = try CodeGenerator(template: colorStyleTemplate)
		textStyleCodeGenerator = try CodeGenerator(template: textStyleTemplate)
		
		generatedColorStylesFile = try exportFolder.createFileIfNeeded(
			named: Constant.colorStylesName,
			fileExtension: colorStyleCodeGenerator.fileExtension
		)
		generatedTextStylesFile = try exportFolder.createFileIfNeeded(
			named: Constant.textStylesName,
			fileExtension: textStyleCodeGenerator.fileExtension
		)
	}
	
	private func updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles() throws {
		// Get all supported file types.
		let supportedFileTypes: Set<FileType> = [
			colorStyleCodeGenerator.fileExtension,
			textStyleCodeGenerator.fileExtension
		]
		
		// Ignore file URLs that will be automatically generated.
		let ignoredFiles: [File] = [
			generatedColorStylesFile,
			generatedTextStylesFile
		]
		
		// Update style references.
		let currentAndMigratedColorStyles = colorStyleParser.currentAndMigratedStyles.map({ currentAndMigratedColorStyle -> (CodeTemplateReplacableStyle, CodeTemplateReplacableStyle) in
			let fileType = colorStyleCodeGenerator.fileExtension
			let currentStyle = CodeTemplateReplacableStyle(colorStyle: currentAndMigratedColorStyle.0, fileType: fileType)
			let migratedStyle = CodeTemplateReplacableStyle(colorStyle: currentAndMigratedColorStyle.1, fileType: fileType)
			return (currentStyle, migratedStyle)
		})
		let currentAndMigratedTextStyles = textStyleParser.currentAndMigratedStyles.map({ currentAndMigratedTextStyle -> (CodeTemplateReplacableStyle, CodeTemplateReplacableStyle) in
			let fileType = textStyleCodeGenerator.fileExtension
			let currentStyle = CodeTemplateReplacableStyle(textStyle: currentAndMigratedTextStyle.0, fileType: fileType)
			let migratedStyle = CodeTemplateReplacableStyle(textStyle: currentAndMigratedTextStyle.1, fileType: fileType)
			return (currentStyle, migratedStyle)
		})
		
		let updateOldColorStyleReferencesOperation = updateOldReferencesFileOperation(
			currentAndMigratedStyles: currentAndMigratedColorStyles
		)
		let updateOldTextStyleReferencesOperation = updateOldReferencesFileOperation(
			currentAndMigratedStyles: currentAndMigratedTextStyles
		)
		
		// Find used deprecated styles.
		let deprecatedColorStyles = colorStyleParser.deprecatedStyles.map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		let deprecatedTextStyles = textStyleParser.deprecatedStyles.map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		
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
	
	private func getAllStyles() -> (colorStyles: [CodeTemplateReplacableStyle], textStyles: [CodeTemplateReplacableStyle]) {
		var deprecatedColorStyles = colorStyleParser.deprecatedStyles.map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		var deprecatedTextStyles = textStyleParser.deprecatedStyles.map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		let newColorStyles = colorStyleParser.newStyles.map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		let newTextStyles = textStyleParser.newStyles.map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedColorStyles,
			usedDeprecatedStyles: usedDeprecatedColorStyles,
			newStyles: newColorStyles
		)
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedTextStyles,
			usedDeprecatedStyles: usedDeprecatedTextStyles,
			newStyles: newTextStyles
		)
		
		let allColorStyles = newColorStyles + deprecatedColorStyles
		let allTextStyles = newTextStyles + deprecatedTextStyles
		
		return (allColorStyles, allTextStyles)
	}
	
	private func generateAndSaveStyleCode(
		version: Version,
		colorStyles: [CodeTemplateReplacableStyle],
		textStyles: [CodeTemplateReplacableStyle]
	) throws {
		let generatedColorStylesCode = colorStyleCodeGenerator.generatedCode(for: [colorStyles], version: version)
		let generatedTextStylesCode = textStyleCodeGenerator.generatedCode(for: [textStyles], version: version)
		
		try generatedColorStylesFile.write(string: generatedColorStylesCode)
		try generatedTextStylesFile.write(string: generatedTextStylesCode)
	}
	
	private func generateAndSaveVersionedStyles(version: Version, colorStyles: [ColorStyle], textStyles: [TextStyle]) throws {
		let versionedStyles = VersionedStyles(
			version: version,
			colorStyles: colorStyles,
			textStyles: textStyles
		)
		
		let encoder = JSONEncoder()
		let rawStylesData = try encoder.encode(versionedStyles)
		try generatedRawStylesFile.write(data: rawStylesData)
	}
	
	private func createBranchAndCommitChanges(version: Version) throws -> (headBranchName: String, baseBranchName: String) {
		print(generatedRawStylesFile)
		let gitManager = try GitManager(
			projectFolderPath: projectFolder.path,
			exportFolderPath: exportFolder.path,
			exportedFileNames: [generatedColorStylesFile.name, generatedTextStylesFile.name, generatedRawStylesFile.name],
			version: version
		)
		try gitManager.createStyleSyncBranch()
		try gitManager.commitAllStyleUpdates()
		try gitManager.checkoutOriginalBranch()
		return (gitManager.styleSyncBranchName, gitManager.originalBranchName)
	}
	
	private func generateScreenshots() throws {
		// TODO: Genericise the 'screenshots' part of this, so that it can easily
		// extend to other platforms
		
		// TODO: Look for other xcode projects, find the best fit.
		guard let xcodeProjectFolder = projectFolder.subfolders.first(where: { $0.extension == .xcodeProject }) else {
			// TODO: Throw
			return
		}
		// Check the project
		// TODO: Perform a better check on the project file
		let _ = try xcodeProjectFolder
			.makeFileSequence(recursive: true, includeHidden: false)
			.filter({ $0.extension == .xcodeScheme })
			.first(where: { xcodeSchemeFile in
				let xcodeSchemeXML = try xcodeSchemeFile.readAsString()
				return xcodeSchemeXML.contains("systemAttachmentLifetime = \"keepNever\"")
		})

		// Run the test
		// TODO: Get all these values as parameters
		let xcodeProject = XcodeProject(projectDirectory: projectFolder)
		let test = XcodeProject.Test(
			testSuite: "StyleGuideUITests",
			testCase: "StyleSyncTests",
			testName: "testSpider"
		)
		try xcodeProject.run(test: test, scheme: "StyleGuide")
		
		// Get the screenshots
		let derivedDataFolder = try Folder(path: "~/Library/Developer/Xcode/DerivedData")
		let lastUpdatedDerivedDataGroup = derivedDataFolder.subfolders
			.filter({ !$0.name.contains("ModuleCache") })
			.sorted { (lhs, rhs) -> Bool in
				return lhs.modificationDate < rhs.modificationDate
			}
			.first
		
		let attachmentsFolder = try lastUpdatedDerivedDataGroup?.subfolder(atPath: "Logs/Test/Attachments")
		attachmentsFolder?.files.forEach({ print($0.name) })
		// TODO: Show an error if these attachments aren't here
		
		// Create or checkout a StyleSyncScreenshots repository
		
	}
	
	private func submitPullRequest(
		headBranchName: String,
		baseBranchName: String,
		oldColorStyles: [CodeTemplateReplacableStyle],
		newColorStyles: [CodeTemplateReplacableStyle],
		oldTextStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle],
		version: Version
	) throws {
		let pullRequestManager = GitHubPullRequestManager(
			username: gitHubUsername,
			repositoryName: gitHubRepositoryName,
			personalAccessToken: gitHubPersonalAccessToken
		)
		
		let headingTemplate: Template = try pullRequestHeadingTemplate.readAsString()
		let styleNameTemplate: Template = try pullRequestStyleNameTemplate.readAsString()
		let addedStyleTableTemplate: Template = try pullRequestAddedStyleTableTemplate.readAsString()
		let updatedStyleTableTemplate: Template = try pullRequestUpdatedStyleTableTemplate.readAsString()
		let deprecatedStylesTableTemplate: Template = try pullRequestDeprecatedStylesTemplate.readAsString()
		
		let pullRequestBodyGenerator = try StyleUpdateSummaryGenerator(
			headingTemplate: headingTemplate,
			styleNameTemplate: styleNameTemplate,
			addedStyleTableTemplate: addedStyleTableTemplate,
			updatedStyleTableTemplate: updatedStyleTableTemplate,
			deprecatedStylesTableTemplate: deprecatedStylesTableTemplate
		)
		
		let body = pullRequestBodyGenerator.body(
			fromOldColorStyles: oldColorStyles,
			newColorStyles: newColorStyles,
			oldTextStyles: oldTextStyles,
			newTextStyles: newTextStyles,
			fileNamesForDeprecatedStyleNames: fileNamesForDeprecatedStyleNames
		)
		
		let pullRequest = GitHub.PullRequest(
			title: "[StyleSync] Update style guide to version \(version.stringRepresentation)",
			body: body,
			head: headBranchName,
			base: baseBranchName
		)

		try pullRequestManager.submit(pullRequest: pullRequest)
	}
	
	private func printUpdatedStyles(
		oldColorStyles: [CodeTemplateReplacableStyle],
		newColorStyles: [CodeTemplateReplacableStyle],
		oldTextStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle]
	) throws {
		let headingTemplate: Template = try consoleHeadingTemplate.readAsString()
		let styleNameTemplate: Template = try consoleStyleNameTemplate.readAsString()
		let addedStyleTableTemplate: Template = try consoleAddedStyleTableTemplate.readAsString()
		let updatedStyleTableTemplate: Template = try consoleUpdatedStyleTableTemplate.readAsString()
		let deprecatedStylesTableTemplate: Template = try consoleDeprecatedStylesTemplate.readAsString()

		let consoleLogGenerator = try StyleUpdateSummaryGenerator(
			headingTemplate: headingTemplate,
			styleNameTemplate: styleNameTemplate,
			addedStyleTableTemplate: addedStyleTableTemplate,
			updatedStyleTableTemplate: updatedStyleTableTemplate,
			deprecatedStylesTableTemplate: deprecatedStylesTableTemplate,
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
				print(error)
				return
			}
			currentAndMigratedStyles.forEach({
				fileString = fileString.replacingOccurrences(of: $0.0.variableName, with: $0.1.variableName)
			})
			
			do {
				try file.write(string: fileString)
			} catch {
				print(error)
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
				print(error)
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
	}
}
