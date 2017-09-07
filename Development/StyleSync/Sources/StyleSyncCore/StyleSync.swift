//
//  StyleSync.swift
//  StyleSync
//
//  Created by Dylan Lewis on 09/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

public final class StyleSync {
	// MARK: - Constants
	
	private enum Constant {
		static let expectedNumberOfArguments = 9
		static let exportedStylesFileName = FileName(name: "ExportedStyles", type: .json)
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
	private var generatedColorStylesFilePath: URL!
	private var generatedTextStylesFilePath: URL!
	private var usedDeprecatedColorStyles: Set<ColorStyle> = []
	private var usedDeprecatedTextStyles: Set<TextStyle> = []
	
	// MARK: - Computed properties
	
	private var sketchDocumentURL: URL {
		return URL(fileURLWithPath: arguments[1])
	}
	private var projectDirectoryURL: URL {
		return URL(fileURLWithPath: arguments[2])
	}
	private var exportDirectoryURL: URL {
		return URL(fileURLWithPath: arguments[3])
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
	private var rawStylesURL: URL {
		return exportDirectoryURL.appending(fileName: Constant.exportedStylesFileName)
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
		try generateAndSaveVersionedStyles(version: version, colorStyles: colorStyles, textStyles: textStyles)
		
		let (headBranchName, baseBranchName) = createBranchAndCommitChanges(version: version)
		try submitPullRequest(
			headBranchName: headBranchName,
			baseBranchName: baseBranchName,
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
			return try decodedObject(at: rawStylesURL)
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
		
		generatedColorStylesFilePath = exportDirectoryURL.appending(
			fileName: .init(name: Constant.colorStylesName, type: colorStyleCodeGenerator.fileExtension)
		)
		generatedTextStylesFilePath = exportDirectoryURL.appending(
			fileName: .init(name: Constant.textStylesName, type: textStyleCodeGenerator.fileExtension)
		)
	}
	
	private func updateFilesInProjectDirectoryAndFindUsedDeprecatedStyles() throws {
		// Get all supported file types.
		let supportedFileTypes: Set<FileName.FileType> = [
			colorStyleCodeGenerator.fileExtension,
			textStyleCodeGenerator.fileExtension
		]
		
		// Ignore file URLs that will be automatically generated.
		let ignoredFileURLs: [URL] = [
			generatedColorStylesFilePath,
			generatedTextStylesFilePath
		]
		
		// Update style references.
		let updateOldColorStyleReferencesOperation = updateOldReferencesFileOperation(currentAndMigratedStyles: colorStyleParser.currentAndMigratedStyles)
		let updateOldTextStyleReferencesOperation = updateOldReferencesFileOperation(currentAndMigratedStyles: textStyleParser.currentAndMigratedStyles)
		
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
		
		try FileManager.default.iterateOverFiles(
			inDirectory: projectDirectoryURL,
			fileTypes: supportedFileTypes,
			ignoredFileURLs: ignoredFileURLs,
			fileOperations: allOperations
		)
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
		
		try generatedColorStylesCode.write(to: generatedColorStylesFilePath, atomically: true, encoding: .utf8)
		try generatedTextStylesCode.write(to: generatedTextStylesFilePath, atomically: true, encoding: .utf8)
	}
	
	private func generateAndSaveVersionedStyles(version: Version, colorStyles: [ColorStyle], textStyles: [TextStyle]) throws {
		let versionedStyles = VersionedStyles(
			version: version,
			colorStyles: colorStyles,
			textStyles: textStyles
		)
		let encoder = JSONEncoder()
		let rawStylesData = try encoder.encode(versionedStyles)
		try rawStylesData.write(to: rawStylesURL, options: .atomic)
	}
	
	private func createBranchAndCommitChanges(version: Version) -> (headBranchName: String, baseBranchName: String) {
		let gitManager = GitManager(projectDirectoryURL: projectDirectoryURL, version: version)
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
		
		let pullRequest = GitHub.PullRequest(
			title: "[StyleSync] Update style guide to version \(version.stringRepresentation)",
			body: body,
			head: headBranchName,
			base: baseBranchName
		)

		try pullRequestManager.submit(pullRequest: pullRequest)
	}
	
	// MARK: - Helpers
	
	private func decodedObject<Object: Decodable>(at url: URL) throws -> Object {
		let decoder = JSONDecoder()
		let decodedData = try Data(contentsOf: url)
		return try decoder.decode(Object.self, from: decodedData)
	}
	
	private func updateOldReferencesFileOperation<S: Style>(currentAndMigratedStyles: [(S, S)]) -> FileOperation {
		return { (filePath, fileContents) in
			var updatedFileContents = fileContents
			currentAndMigratedStyles.forEach({ updatedFileContents = updatedFileContents
				.replacingOccurrences(of: $0.0.codeName, with: $0.1.codeName) })
			
			do {
				try updatedFileContents.write(to: filePath, atomically: true, encoding: .utf8)
			} catch {
				print(error)
			}
		}
	}
	
	private func findUsedDeprecatedStylesFileOperation<S: Style>(deprecatedStyles: [S], usedDeprecatedStyles: inout Set<S>) -> FileOperation {
		return { (_, fileContents) in
			deprecatedStyles.forEach({ style in
				if fileContents.contains(style.codeName) {
					usedDeprecatedStyles.insert(style)
				}
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
		case failedToCreateStringFromData
	}
}
