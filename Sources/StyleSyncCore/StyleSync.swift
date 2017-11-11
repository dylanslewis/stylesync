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
	}
	
	// MARK: - Stored variables

	private var config: Config!
	private let projectFolder: Folder = .current
	
	// MARK: - Initializer
	
	public init(arguments: [String] = CommandLine.arguments) {
		#if os(Linux)
			print("StyleSync does not support Linux")
			exit(1)
		#endif
		guard arguments.count == 1 else {
			ErrorManager.log(fatalError: Error.invalidArguments, context: .arguments)
		}
		let configManager = ConfigManager(projectFolder: projectFolder)
		do {
			self.config = try configManager.getConfig()
		} catch {
			ErrorManager.log(fatalError: error, context: .config)
		}
	}
	
	// MARK: - Run
	
	public func run() {
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
		
		run(
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
	) {
		let sketchManager = SketchManager(sketchFile: sketchDocumentFile)
		let sketchDocument: SketchDocument
		do {
			sketchDocument = try sketchManager.getSketchDocument()
		} catch {
			ErrorManager.log(fatalError: error, context: .sketch)
		}
		
		let generatedRawTextStylesFile: File
		let generatedRawColorStylesFile: File
		do {
			generatedRawTextStylesFile = try exportTextFolder.createFileIfNeeded(
				named: Constant.exportedTextStylesFileName,
				fileExtension: Constant.exportedStylesFileType
			)
			generatedRawColorStylesFile = try exportColorsFolder.createFileIfNeeded(
				named: Constant.exportedColorStylesFileName,
				fileExtension: Constant.exportedStylesFileType
			)
		} catch {
			ErrorManager.log(fatalError: error, context: .files)
		}
			
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
		
		let styleExporter = StyleExporter(
			latestTextStyles: latestTextStyles,
			latestColorStyles: latestColorStyles,
			previouslyExportedTextStyles: previouslyExportedTextStyles,
			previouslyExportedColorStyles: previouslyExportedColorStyles,
			projectFolder: projectFolder,
			textStyleTemplateFile: textStyleTemplateFile,
			colorStyleTemplateFile: colorStyleTemplateFile,
			exportTextFolder: exportTextFolder,
			exportColorsFolder: exportColorsFolder,
			generatedRawTextStylesFile: generatedRawTextStylesFile,
			generatedRawColorStylesFile: generatedRawColorStylesFile,
			previousStylesVersion: previousStylesVersion
		)
		do {
			try styleExporter.exportStyles()
		} catch {
			ErrorManager.log(fatalError: error, context: .styleExporting)
		}
		
		guard let gitHubPersonalAccessToken = gitHubPersonalAccessToken else {
			print("\nIf you'd like to branch, commit and raise a pull request for these updates, add your GitHub Personal Access token to styleSyncConfig.json")
			exit(0)
		}
		
		let generatedTextStylesFile: File = styleExporter.generatedTextStylesFile
		let generatedColorStylesFile: File = styleExporter.generatedColorStylesFile
		let fileNamesForDeprecatedStyleNames = styleExporter.fileNamesForDeprecatedStyleNames
		let version: Version = styleExporter.version
		let oldTextStyles: [CodeTemplateReplacableStyle] = styleExporter.oldTextStyles
		let oldColorStyles: [CodeTemplateReplacableStyle] = styleExporter.oldColorStyles
		let newTextStyles: [CodeTemplateReplacableStyle] = styleExporter.newTextStyles
		let newColorStyles: [CodeTemplateReplacableStyle] = styleExporter.newColorStyles

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
				newTextStyles: newTextStyles,
				oldColorStyles: oldColorStyles,
				newColorStyles: newColorStyles
			)
		} catch {
			ErrorManager.log(fatalError: error, context: .gitHub)
		}
		exit(0)
	}
}

extension StyleSync {
	enum Error: Swift.Error {
		case invalidArguments
		case noStylesFound
	}
}
