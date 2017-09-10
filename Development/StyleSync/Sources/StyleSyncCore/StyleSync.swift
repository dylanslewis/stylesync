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
		static let exportedStylesFileType: FileName.FileType = .json
		static let colorStylesName = "ColorStyles"
		static let textStylesName = "TextStyles"
	}
	
	// MARK: - Stored properties
	
	private let arguments: [String]
	private let fileManager: FileManager
	
	private var colorStyleParser: StyleParser<ColorStyle>!
	private var textStyleParser: StyleParser<TextStyle>!
	private var colorStyleCodeGenerator: CodeGenerator!
	private var textStyleCodeGenerator: CodeGenerator!
	private var usedDeprecatedColorStyles: Set<ColorStyle> = []
	private var usedDeprecatedTextStyles: Set<TextStyle> = []
	
	private var projectFolder: Folder!
	private var exportFolder: Folder!

	private var generatedColorStylesFile: File!
	private var generatedTextStylesFile: File!
	private var generatedRawStylesFile: File!
	
	// MARK: - Computed properties
	
	private var sketchDocumentURL: URL {
		return URL(fileURLWithPath: arguments[1])
	}
	private var colorStyleTemplateURL: URL {
		return URL(fileURLWithPath: arguments[4])
	}
	private var textStyleTemplateURL: URL {
		return URL(fileURLWithPath: arguments[5])
	}
	private var gitHubUsername: String {
		return arguments[6]
	}
	private var gitHubRepositoryName: String {
		return arguments[7]
	}
	private var gitHubPersonalAccessToken: String {
		return arguments[8]
	}
	private var gitHubTemplatesBaseURL: URL {
		return URL(fileURLWithPath: "\(fileManager.currentDirectoryPath)/Sources/StyleSyncCore/Templates/GitHub/")
	}
	private var pullRequestHeadingTemplateURL: URL {
		return gitHubTemplatesBaseURL.appendingPathComponent("Heading")
	}
	private var pullRequestStyleNameTemplateURL: URL {
		return gitHubTemplatesBaseURL.appendingPathComponent("StyleName")
	}
	private var pullRequestAddedStyleTableTemplateURL: URL {
		return gitHubTemplatesBaseURL.appendingPathComponent("NewStyleTable")
	}
	private var pullRequestUpdatedStyleTableTemplateURL: URL {
		return gitHubTemplatesBaseURL.appendingPathComponent("UpdatedStyleTable")
	}
	private var pullRequestDeprecatedStylesTemplateURL: URL {
		return gitHubTemplatesBaseURL.appendingPathComponent("DeprecatedStylesTable")
	}
	
	// MARK: - Initializer
	
	public init(
		arguments: [String] = CommandLine.arguments,
		fileManager: FileManager = .default
	) throws {
		if arguments.count != Constant.expectedNumberOfArguments {
			throw Error.invalidArguments
		}
		self.arguments = arguments
		self.fileManager = fileManager
		try createFolderReferences(using: arguments)
	}
	
	private func createFolderReferences(using arguments: [String]) throws {
		self.projectFolder = try Folder(path: arguments[2])
		self.exportFolder = try Folder(path: arguments[3])
	}

	// MARK: - Run

	public func run() throws {
		let sketchDocument: SketchDocument = try decodedObject(at: sketchDocumentURL)
		
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
//		try generateAndSaveVersionedStyles(version: version, colorStyles: colorStyles, textStyles: textStyles)
		
//		let (headBranchName, baseBranchName) = createBranchAndCommitChanges(version: version)
		try submitPullRequest(
			headBranchName: "headBranchName",
			baseBranchName: "baseBranchName",
			oldColorStyles: previousExportedStyles?.colorStyles ?? [],
			newColorStyles: colorStyleParser.newStyles,
			oldTextStyles: previousExportedStyles?.textStyles ?? [],
			newTextStyles: textStyleParser.newStyles,
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
		let colorStyleTemplateData = try Data(contentsOf: colorStyleTemplateURL)
		let textStyleTemplateData = try Data(contentsOf: textStyleTemplateURL)
		
		guard
			let colorStyleTemplate: Template = String(data: colorStyleTemplateData, encoding: .utf8),
			let textStyleTemplate: Template = String(data: textStyleTemplateData, encoding: .utf8)
		else {
			throw Error.failedToCreateStringFromData
		}
		
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
		let supportedFileTypes: Set<FileName.FileType> = [
			colorStyleCodeGenerator.fileExtension,
			textStyleCodeGenerator.fileExtension
		]
		
		// Ignore file URLs that will be automatically generated.
		let ignoredFiles: [File] = [
			generatedColorStylesFile,
			generatedTextStylesFile
		]
		
		// Update style references.
		let updateOldColorStyleReferencesOperation = updateOldReferencesFileOperation(currentAndMigratedStyles: colorStyleParser.currentAndMigratedStyles)
		let updateOldTextStyleReferencesOperation = updateOldReferencesFileOperation(currentAndMigratedStyles: textStyleParser.currentAndMigratedStyles)
		
//		let fileReferencesForDeprecatedStyle: [TextStyle: [String]] = [:]
		
		// Find used deprecated styles.
		let findUsedDeprecatedColorStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: colorStyleParser.deprecatedStyles,
			usedDeprecatedStyles: &usedDeprecatedColorStyles
		)
		let findUsedDeprecatedTextStylesOperation = findUsedDeprecatedStylesFileOperation(
			deprecatedStyles: textStyleParser.deprecatedStyles,
			usedDeprecatedStyles: &usedDeprecatedTextStyles
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
			usedDeprecatedStyles: Array(usedDeprecatedColorStyles),
			newStyles: colorStyleParser.newStyles
		)
		removeUnusedDeprecatedStyles(
			deprecatedStyles: &deprecatedTextStyles,
			usedDeprecatedStyles: Array(usedDeprecatedTextStyles),
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
	
	private func createBranchAndCommitChanges(version: Version) -> (headBranchName: String, baseBranchName: String) {
		let gitManager = GitManager(projectFolderPath: projectFolder.path, version: version)
		gitManager.createStyleSyncBranch()
		gitManager.commitAllStyleUpdates()
		gitManager.checkoutOriginalBranch()
		return (gitManager.styleSyncBranchName, gitManager.originalBranchName)
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
		
		let headingTemplate: Template = try String(contentsOfURL: pullRequestHeadingTemplateURL)
		let styleNameTemplate: Template = try String(contentsOfURL: pullRequestStyleNameTemplateURL)
		let addedStyleTableTemplate: Template = try String(contentsOfURL: pullRequestAddedStyleTableTemplateURL)
		let updatedStyleTableTemplate: Template = try String(contentsOfURL: pullRequestUpdatedStyleTableTemplateURL)
		let deprecatedStylesTableTemplate: Template = try String(contentsOfURL: pullRequestDeprecatedStylesTemplateURL)
		
		let pullRequestBodyGenerator = try PullRequestBodyGenerator(
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
			newTextStyles: newTextStyles
		)
		
		print(body)
		
		let pullRequest = GitHub.PullRequest(
			title: "[StyleSync] Update style guide to version \(version.stringRepresentation)",
			body: body,
			head: headBranchName,
			base: baseBranchName
		)

//		try pullRequestManager.submit(pullRequest: pullRequest)
	}
	
	// MARK: - Helpers
	
	private func decodedObject<Object: Decodable>(at url: URL) throws -> Object {
		let decoder = JSONDecoder()
		let decodedData = try Data(contentsOf: url)
		return try decoder.decode(Object.self, from: decodedData)
	}
	
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
	
	private func findUsedDeprecatedStylesFileOperation<S: Style>(deprecatedStyles: [S], usedDeprecatedStyles: inout Set<S>) -> FileOperation {
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
				.forEach({ usedDeprecatedStyles.insert($0) })
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
		case failedToCreateStringFromData
	}
}
