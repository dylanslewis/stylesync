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
	private var filesForDeprecatedColorStyle: [ColorStyle: [File]] = [:]
	private var filesForDeprecatedTextStyle: [TextStyle: [File]] = [:]

	private var projectFolder: Folder!
	private var exportFolder: Folder!

	private var sketchDocument: File!
	private var colorStyleTemplate: File!
	private var textStyleTemplate: File!
	
	private var gitHubUsername: String!
	private var gitHubRepositoryName: String!
	private var gitHubPersonalAccessToken: String!
	
	private var pullRequestHeadingTemplate: File!
	private var pullRequestStyleNameTemplate: File!
	private var pullRequestAddedStyleTableTemplate: File!
	private var pullRequestUpdatedStyleTableTemplate: File!
	private var pullRequestDeprecatedStylesTemplate: File!
	
	private var generatedColorStylesFile: File!
	private var generatedTextStylesFile: File!
	private var generatedRawStylesFile: File!
	
	// MARK: - Computed properties

	private var usedDeprecatedColorStyles: [ColorStyle] {
		return Array(filesForDeprecatedColorStyle.keys)
	}
	private var usedDeprecatedTextStyles: [TextStyle] {
		return Array(filesForDeprecatedTextStyle.keys)
	}
	
	// MARK: - Initializer
	
	public init(arguments: [String] = CommandLine.arguments) throws {
		guard arguments.count == Constant.expectedNumberOfArguments else {
			throw Error.invalidArguments
		}
		try parse(arguments: arguments)
		try createGitHubTemplateReferences()
	}
	
	private func parse(arguments: [String]) throws {
		self.sketchDocument = try File(path: arguments[1])
		self.projectFolder = try Folder(path: arguments[2])
		self.exportFolder = try Folder(path: arguments[3])
		self.colorStyleTemplate = try File(path: arguments[4])
		self.textStyleTemplate = try File(path: arguments[5])
		self.gitHubUsername = arguments[6]
		self.gitHubRepositoryName = arguments[7]
		self.gitHubPersonalAccessToken = arguments[8]
	}
	
	private func createGitHubTemplateReferences() throws {
		let gitHubTemplatesBaseURL = try Folder.current.subfolder(atPath: "StyleSync/Sources/StyleSyncCore/Templates/GitHub")
		self.pullRequestHeadingTemplate = try gitHubTemplatesBaseURL.file(named: "Heading")
		self.pullRequestStyleNameTemplate = try gitHubTemplatesBaseURL.file(named: "StyleName")
		self.pullRequestAddedStyleTableTemplate = try gitHubTemplatesBaseURL.file(named: "NewStyleTable")
		self.pullRequestUpdatedStyleTableTemplate = try gitHubTemplatesBaseURL.file(named: "UpdatedStyleTable")
		self.pullRequestDeprecatedStylesTemplate = try gitHubTemplatesBaseURL.file(named: "DeprecatedStylesTable")
	}

	// MARK: - Run

	public func run() throws {
		let sketchDocument: SketchDocument = try self.sketchDocument.readAsDecodedJSON()
		
		let previousExportedStyles = getPreviousExportedStyles()
		createStyleParsers(using: sketchDocument, previousExportedStyles: previousExportedStyles)
		try createStyleCodeGenerators()
		try updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles()
		
		let (colorStyles, textStyles) = getAllStyles()
		let version = Version(
			oldColorStyles: previousExportedStyles?.colorStyles,
			oldTextStyles: previousExportedStyles?.textStyles,
			newColorStyles: colorStyles,
			newTextStyles: textStyles,
			currentVersion: previousExportedStyles?.version
		)
		
		guard previousExportedStyles?.version == nil || version != previousExportedStyles?.version else {
			return
		}

		try generateAndSaveStyleCode(version: version, colorStyles: colorStyles, textStyles: textStyles)
		try generateAndSaveVersionedStyles(version: version, colorStyles: colorStyles, textStyles: textStyles)

		let (headBranchName, baseBranchName) = try createBranchAndCommitChanges(version: version)
//		try generateScreenshots()
		
		try submitPullRequest(
			headBranchName: headBranchName,
			baseBranchName: baseBranchName,
			oldColorStyles: previousExportedStyles?.colorStyles ?? [],
			newColorStyles: colorStyles,
			oldTextStyles: previousExportedStyles?.textStyles ?? [],
			newTextStyles: textStyles,
			version: version
		)
	}
	
	// MARK: - Actions
	
	private func getPreviousExportedStyles() -> VersionedStyles? {
		do {
			let rawStylesFile = try exportFolder.file(
				named: Constant.exportedStylesFileName,
				fileExtension: Constant.exportedStylesFileType
			)
			return try rawStylesFile.readAsDecodedJSON()
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
		let updateOldColorStyleReferencesOperation = updateOldReferencesFileOperation(
			currentAndMigratedStyles: colorStyleParser.currentAndMigratedStyles
		)
		let updateOldTextStyleReferencesOperation = updateOldReferencesFileOperation(
			currentAndMigratedStyles: textStyleParser.currentAndMigratedStyles
		)
		
		// Find used deprecated styles.
		let findUsedDeprecatedColorStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: colorStyleParser.deprecatedStyles,
			filesForDeprecatedStyle: &filesForDeprecatedColorStyle
		)
		let findUsedDeprecatedTextStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: textStyleParser.deprecatedStyles,
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
	
	private func getAllStyles() -> (colorStyles: [ColorStyle], textStyles: [TextStyle]) {
		var deprecatedColorStyles = colorStyleParser.deprecatedStyles
		var deprecatedTextStyles = textStyleParser.deprecatedStyles
		
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedColorStyles,
			usedDeprecatedStyles: usedDeprecatedColorStyles,
			newStyles: colorStyleParser.newStyles
		)
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedTextStyles,
			usedDeprecatedStyles: usedDeprecatedTextStyles,
			newStyles: textStyleParser.newStyles
		)
		
		let allColorStyles = colorStyleParser.newStyles + deprecatedColorStyles
		let allTextStyles = textStyleParser.newStyles + deprecatedTextStyles
		
		return (allColorStyles, allTextStyles)
	}
	
	private func generateAndSaveStyleCode(version: Version, colorStyles: [ColorStyle], textStyles: [TextStyle]) throws {
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
		
		let rawStylesFile = try exportFolder.createFileIfNeeded(
			named: Constant.exportedStylesFileName,
			fileExtension: Constant.exportedStylesFileType
 		)
		
		let encoder = JSONEncoder()
		let rawStylesData = try encoder.encode(versionedStyles)
		try rawStylesFile.write(data: rawStylesData)
	}
	
	private func createBranchAndCommitChanges(version: Version) throws -> (headBranchName: String, baseBranchName: String) {
		let gitManager = try GitManager(projectFolderPath: projectFolder.path, version: version)
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
		oldColorStyles: [ColorStyle],
		newColorStyles: [ColorStyle],
		oldTextStyles: [TextStyle],
		newTextStyles: [TextStyle],
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
		
		let pullRequestBodyGenerator = try PullRequestBodyGenerator(
			headingTemplate: headingTemplate,
			styleNameTemplate: styleNameTemplate,
			addedStyleTableTemplate: addedStyleTableTemplate,
			updatedStyleTableTemplate: updatedStyleTableTemplate,
			deprecatedStylesTableTemplate: deprecatedStylesTableTemplate
		)
		
		var fileNamesForDeprecatedStyleNames: [String: [String]] = [:]
		Array(filesForDeprecatedColorStyle.keys)
			.forEach { style in
				let filesForStyle = filesForDeprecatedColorStyle[style]
				let fileNames: [String] = filesForStyle?.map({ $0.name }) ?? []
				fileNamesForDeprecatedStyleNames[style.codeName] = fileNames
		}
		Array(filesForDeprecatedTextStyle.keys)
			.forEach { style in
				let filesForStyle = filesForDeprecatedTextStyle[style]
				let fileNames: [String] = filesForStyle?.map({ $0.name }) ?? []
				fileNamesForDeprecatedStyleNames[style.codeName] = fileNames
		}
		
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
	
	// MARK: - Helpers
	
	private func updateOldReferencesFileOperation<S: Style>(currentAndMigratedStyles: [(S, S)]) -> FileOperation {
		return { file in
			var fileString: String
			do {
				fileString = try file.readAsString()
			} catch {
				print(error)
				return
			}
			currentAndMigratedStyles.forEach({
				fileString = fileString.replacingOccurrences(of: $0.0.codeName, with: $0.1.codeName)
			})
			
			do {
				try file.write(string: fileString)
			} catch {
				print(error)
			}
		}
	}
	
	private func findUsedDeprecatedStylesFileOperation<S: Style>(
		deprecatedStyles: [S],
		filesForDeprecatedStyle: inout [S: [File]]
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
				.filter({ fileString.contains($0.codeName) })
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
	
	private func removeUnusedDeprecatedStyles<S: Style & Hashable>(deprecatedStyles: inout [S], usedDeprecatedStyles: [S], newStyles: [S]) {
		// Only styles that are still in the project should be deprecated, and
		// any others removed completely.
		deprecatedStyles = deprecatedStyles
			.filter({ return usedDeprecatedStyles.contains($0) })
			.filter({ style -> Bool in
				// If a style is removed but another is added with the same
				// name, then remove the deprecated one to avoid compilation
				// issues.
				if newStyles.contains(where: { return $0.codeName == style.codeName }) {
					print("⚠️ Style with name \(style.codeName) was removed and added with a different name.")
					return false
				} else {
					return true
				}
			})
	}
}

extension StyleSync {
	enum Error: Swift.Error {
		case invalidArguments
	}
}
