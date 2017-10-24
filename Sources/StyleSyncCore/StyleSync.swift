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
		static let colorStylesName = "ColorStyles"
		static let textStylesName = "TextStyles"
		
		enum Config {
			static let fileName = "styleSyncConfig"
			static let fileType: FileType = .json
		}
	}
	
	// MARK: - Stored properties

	private var sketchFile: File!
	private var colorStyleTemplate: File!
	private var textStyleTemplate: File!
	private var gitHubPersonalAccessToken: String?
	
	private var colorStyleParser: StyleParser<ColorStyle>!
	private var textStyleParser: StyleParser<TextStyle>!
	private var colorStyleCodeGenerator: CodeGenerator!
	private var textStyleCodeGenerator: CodeGenerator!
	private var filesForDeprecatedColorStyle: [CodeTemplateReplacableStyle: [File]] = [:]
	private var filesForDeprecatedTextStyle: [CodeTemplateReplacableStyle: [File]] = [:]

	private let projectFolder: Folder = .current
	private var exportTextFolder: Folder!
	private var exportColorsFolder: Folder!

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
	private var generatedRawTextStylesFile: File!
	private var generatedRawColorStylesFile: File!
	
	// MARK: - Computed properties

	private var usedDeprecatedColorStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedColorStyle.keys)
	}
	private var usedDeprecatedTextStyles: [CodeTemplateReplacableStyle] {
		return Array(filesForDeprecatedTextStyle.keys)
	}
	
	// MARK: - Initializer
	
	public init(arguments: [String] = CommandLine.arguments) throws {
		guard arguments.count == 1 else {
			throw Error.invalidArguments
		}
		try getConfig()
		try createZipManager(forSketchFile: sketchFile)
		try createGitHubTemplateReferences()
		try createConsoleTemplateReferences()
	}
	
	// MARK: - Config
	
	private func getConfig() throws {
		do {
			try readConfig()
		} catch Error.failedToFindFile {
			try createConfig()
		} catch {
			throw Error.failedToReadFile
		}
	}
	
	private func readConfig() throws {
		guard let configFile = try? projectFolder.file(
			named: Constant.Config.fileName,
			fileExtension: Constant.Config.fileType
		) else {
			throw Error.failedToFindFile
		}
		let config: Config = try configFile.readAsDecodedJSON()
		try parse(config: config)
	}
	
	private func parse(config: Config) throws {
		self.sketchFile = try File(path: config.sketchDocument)
		self.exportTextFolder = try Folder(path: config.textStyle.exportDirectory)
		self.exportColorsFolder = try Folder(path: config.colorStyle.exportDirectory)
		self.colorStyleTemplate = try File(path: config.colorStyle.template)
		self.textStyleTemplate = try File(path: config.textStyle.template)
		self.gitHubPersonalAccessToken = config.gitHubPersonalAccessToken
	}
	
	private func createConfig() throws {
		let questionaire = Questionaire(creatable: Config()) { (creatable) in
			guard let completedConfig = creatable as? Config else {
				return
			}
			do {
				try self.save(config: completedConfig)
			} catch {
				print(error)
			}
		}
		questionaire.startQuestionaire()
		
		try readConfig()
	}
	
	private func save(config: Config) throws {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		do {
			let configFileData = try encoder.encode(config)
			guard let configFileString = String(data: configFileData, encoding: .utf8) else {
				throw Error.failedToSaveFile
			}
			
			let styleSyncConfig = try projectFolder.createFileIfNeeded(
				named: Constant.Config.fileName,
				fileExtension: Constant.Config.fileType
			)
			try styleSyncConfig.write(string: configFileString)
		} catch {
			print(error)
		}
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
		
		let oldColorStyles = (previousExportedStyles?.color.colorStyles ?? []).map({
			CodeTemplateReplacableStyle(colorStyle: $0, fileType: colorStyleCodeGenerator.fileExtension)
		})
		let oldTextStyles = (previousExportedStyles?.text.textStyles ?? []).map({
			CodeTemplateReplacableStyle(textStyle: $0, fileType: textStyleCodeGenerator.fileExtension)
		})
		
		let (colorStyles, textStyles) = getAllStyles()
		let currentVersion = previousExportedStyles?.text.version ?? previousExportedStyles?.color.version
		let version = Version(
			oldColorStyles: oldColorStyles,
			oldTextStyles: oldTextStyles,
			newColorStyles: colorStyles,
			newTextStyles: textStyles,
			currentVersion: currentVersion
		)
		
		guard currentVersion == nil || version != currentVersion else {
			print("🎉 Your styles are already up to date!")
			return
		}

		try generateAndSaveStyleCode(version: version, colorStyles: colorStyles, textStyles: textStyles)
		try generateAndSaveVersionedStyles(
			version: version,
			colorStyles: colorStyles.map({ $0.style as? ColorStyle }).flatMap({$0}),
			textStyles: textStyles.map({ $0.style as? TextStyle }).flatMap({$0})
		)
		try printUpdatedStyles(
			oldColorStyles: oldColorStyles,
			newColorStyles: colorStyles,
			oldTextStyles: oldTextStyles,
			newTextStyles: textStyles
		)
		
		guard let gitHubPersonalAccessToken = gitHubPersonalAccessToken else {
			print("Your files have been generated. If you'd like to branch, commit and raise a pull request for these updates, add your GitHub Personal Access token to styleSyncConfig.json")
			return
		}

		do {
			let (gitHubUsername, gitHubRepositoryName) = try getGitHubUsernameAndRepositoryName()
			let (headBranchName, baseBranchName) = try createBranchAndCommitChanges(version: version)
			try generateScreenshots()
			
			try submitPullRequest(
				username: gitHubUsername,
				repositoryName: gitHubRepositoryName,
				personalAccessToken: gitHubPersonalAccessToken,
				headBranchName: headBranchName,
				baseBranchName: baseBranchName,
				oldColorStyles: oldColorStyles,
				newColorStyles: colorStyles,
				oldTextStyles: oldColorStyles,
				newTextStyles: textStyles,
				version: version
			)
		} catch {
			if let shellOutError = error as? ShellOutError {
				print(shellOutError.message)
			} else {
				throw error
			}
		}
	}
	
	// MARK: - Actions

	private func getPreviousExportedStyles() throws -> (text: VersionedStyle.Text, color: VersionedStyle.Color)? {
		generatedRawTextStylesFile = try exportTextFolder.createFileIfNeeded(
			named: Constant.exportedTextStylesFileName,
			fileExtension: Constant.exportedStylesFileType
		)
		generatedRawColorStylesFile = try exportColorsFolder.createFileIfNeeded(
			named: Constant.exportedColorStylesFileName,
			fileExtension: Constant.exportedStylesFileType
		)
		
		guard
			let versionedTextStyles: VersionedStyle.Text = try? generatedRawTextStylesFile.readAsDecodedJSON(),
			let versionedColorStyles: VersionedStyle.Color = try? generatedRawColorStylesFile.readAsDecodedJSON()
		else {
			return nil
		}
		return (versionedTextStyles, versionedColorStyles)
	}
	
	private func createStyleParsers(
		using sketchDocument: SketchDocument,
		previousExportedStyles: (text: VersionedStyle.Text, color: VersionedStyle.Color)?
	) {
		colorStyleParser = StyleParser(
			sketchDocument: sketchDocument,
			previousStyles: previousExportedStyles?.color.colorStyles
		)
		textStyleParser = StyleParser(
			sketchDocument: sketchDocument,
			colorStyles: colorStyleParser.newStyles,
			previousStyles: previousExportedStyles?.text.textStyles
		)
	}
	
	private func createStyleCodeGenerators() throws {
		let colorStyleTemplate: Template = try self.colorStyleTemplate.readAsString()
		let textStyleTemplate: Template = try self.textStyleTemplate.readAsString()
		
		colorStyleCodeGenerator = try CodeGenerator(template: colorStyleTemplate)
		textStyleCodeGenerator = try CodeGenerator(template: textStyleTemplate)
		
		generatedTextStylesFile = try exportTextFolder.createFileIfNeeded(
			named: Constant.textStylesName,
			fileExtension: textStyleCodeGenerator.fileExtension
		)
		generatedColorStylesFile = try exportColorsFolder.createFileIfNeeded(
			named: Constant.colorStylesName,
			fileExtension: colorStyleCodeGenerator.fileExtension
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
		let versionedTextStyles = VersionedStyle.Text(version: version, textStyles: textStyles)
		let versionedColorStyles = VersionedStyle.Color(version: version, colorStyles: colorStyles)
		
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let rawTextStylesData = try encoder.encode(versionedTextStyles)
		let rawColorStylesData = try encoder.encode(versionedColorStyles)
		
		try generatedRawTextStylesFile.write(data: rawTextStylesData)
		try generatedRawColorStylesFile.write(data: rawColorStylesData)
	}
	
	private func getGitHubUsernameAndRepositoryName() throws -> (username: String, repositoryName: String) {
		let shellOutput = try shellOut(to: .gitGetOriginURL())
		guard
			shellOutput.contains("git@github.com"),
			let userNameAndRepositoryName = shellOutput.split(separator: ":").last?.split(separator: "/"),
			userNameAndRepositoryName.count == 2,
			let username = userNameAndRepositoryName.first,
			let repositoryName = userNameAndRepositoryName.last
		else {
			throw Error.unexpectedConsoleOutput
		}
		return (String(username), String(repositoryName))
	}
	
	private func createBranchAndCommitChanges(version: Version) throws -> (headBranchName: String, baseBranchName: String) {
		let exportedTextFileNames = [generatedTextStylesFile, generatedRawTextStylesFile]
			.map({ $0.name })
		let exportedColorsFileNames = [generatedColorStylesFile, generatedRawColorStylesFile]
			.map({ $0.name })
		
		let gitManager = try GitManager(
			projectFolderPath: projectFolder.path,
			exportTextFolderPath: exportTextFolder.path,
			exportColorsFolderPath: exportColorsFolder.path,
			exportedTextFileNames: exportedTextFileNames,
			exportedColorsFileNames: exportedColorsFileNames,
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
		username: String,
		repositoryName: String,
		personalAccessToken: String,
		headBranchName: String,
		baseBranchName: String,
		oldColorStyles: [CodeTemplateReplacableStyle],
		newColorStyles: [CodeTemplateReplacableStyle],
		oldTextStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle],
		version: Version
	) throws {
		let pullRequestManager = GitHubPullRequestManager(
			username: username,
			repositoryName: repositoryName,
			personalAccessToken: personalAccessToken
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
		case failedToFindFile
		case failedToReadFile
		case failedToSaveFile
		case unexpectedConsoleOutput
	}
}
