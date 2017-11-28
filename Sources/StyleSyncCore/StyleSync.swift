//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Cocoa
import Files
import ShellOut

enum StyleInput {
	case sketch(sketchDocument: SketchDocument)
	case lona(colors: [Lona.Color], textStyles: [Lona.Text])
}

public final class StyleSync {
	// MARK: - Constants
	
	private enum Constant {
		static let exportedTextStylesFileName = "exportedTextStyles"
		static let exportedColorStylesFileName = "exportedColorStyles"
		static let exportedStylesFileType: FileType = .json
	}
	
	// MARK: - Stored variables

	private var config: Config!
	private let projectFolder: Folder!
	
	// MARK: - Initializer
	
	public init(arguments: [String] = CommandLine.arguments, projectFolder: Folder = .current) {
		#if os(Linux)
			ErrorManager.log(fatalError: .unsupportedPlatform, context: .initialization)
		#endif
		
		switch arguments.count {
		case 1:
			break
		case 2 where arguments.last == "-h":
			print(StyleSync.helpMessage)
			exit(0)
		case 2 where arguments.last == "-v":
			print(StyleSync.versionMessage)
			exit(0)
		default:
			print(StyleSync.helpMessage)
			ErrorManager.log(fatalError: Error.invalidArguments, context: .arguments)
		}
		
		let configManager = ConfigManager(projectFolder: projectFolder)
		do {
			config = try configManager.getConfig()
		} catch {
			ErrorManager.log(fatalError: error, context: .config)
		}
		self.projectFolder = projectFolder
	}
	
	// MARK: - Run
	
	public func run() {
		var sketchDocumentFile: File?
		var lonaColorsFile: File?
		var lonaTextStylesFile: File?
		let exportTextFolder: Folder
		let exportColorsFolder: Folder
		let textStyleTemplateFile: File
		let colorStyleTemplateFile: File
		do {
			if let sketchDocument = config.sketchDocument {
				sketchDocumentFile = try File(path: sketchDocument)
			}
			if let lona = config.lona {
				lonaColorsFile = try File(path: lona.colors)
				lonaTextStylesFile = try File(path: lona.text)
			}
			exportTextFolder = try Folder(path: config.textStyle.exportDirectory)
			exportColorsFolder = try Folder(path: config.colorStyle.exportDirectory)
			textStyleTemplateFile = try File(path: config.textStyle.template)
			colorStyleTemplateFile = try File(path: config.colorStyle.template)
		} catch {
			ErrorManager.log(fatalError: error, context: .files)
		}
		
		run(
			sketchDocumentFile: sketchDocumentFile,
			lonaColorsFile: lonaColorsFile,
			lonaTextStylesFile: lonaTextStylesFile,
			exportTextFolder: exportTextFolder,
			exportColorsFolder: exportColorsFolder,
			textStyleTemplateFile: textStyleTemplateFile,
			colorStyleTemplateFile: colorStyleTemplateFile,
			gitHubPersonalAccessToken: config.gitHubPersonalAccessToken
		)
	}
	
	public func run(
		sketchDocumentFile: File?,
		lonaColorsFile: File?,
		lonaTextStylesFile: File?,
		exportTextFolder: Folder,
		exportColorsFolder: Folder,
		textStyleTemplateFile: File,
		colorStyleTemplateFile: File,
		gitHubPersonalAccessToken: String?
	) {
		let styleInput: StyleInput
		if let sketchDocumentFile = sketchDocumentFile {
			let sketchManager = SketchManager(sketchFile: sketchDocumentFile)
			let sketchDocument: SketchDocument
			do {
				sketchDocument = try sketchManager.getSketchDocument()
			} catch {
				ErrorManager.log(fatalError: error, context: .sketch)
			}
			styleInput = .sketch(sketchDocument: sketchDocument)
		} else if let lonaColorsFile = lonaColorsFile, let lonaTextStylesFile = lonaTextStylesFile {
			let lonaColors: Lona
			let lonaTextStyles: Lona
			do {
				lonaColors = try lonaColorsFile.readAsDecodedJSON()
				lonaTextStyles = try lonaTextStylesFile.readAsDecodedJSON()
			} catch {
				ErrorManager.log(fatalError: error, context: .sketch)
			}
			// TODO: Don't force unwrap. Decode these better.
			styleInput = .lona(colors: lonaColors.colors!, textStyles: lonaTextStyles.textStyles!)
		} else {
			exit(1)
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
			styleInput: styleInput
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
			ErrorManager.log(fatalError: error, context: .stylesExport)
		}
		
		guard let gitHubPersonalAccessToken = gitHubPersonalAccessToken else {
			print("""
			
			If you'd like to branch, commit and raise a pull request for these updates, add your GitHub Personal Access token to `stylesyncConfig.json`

			You create one with `repo` access at \(GitHubLink.personalAccessTokens).
			""")
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

private extension StyleSync {
	static var helpMessage: String {
		return "stylesync v\(version)\n"
			+ "\n"
			+ "Run `stylesync` in the root directory of your project to set up a config file."
	}
	
	static var versionMessage: String {
		return "stylesync, version \(version)"
	}
	
	private static let version = "1.0.0"
}

extension StyleSync {
	enum Error: Swift.Error, CustomStringConvertible {
		case unsupportedPlatform
		case invalidArguments
		case noStylesFound
		
		/// A string describing the error.
		public var description: String {
			switch self {
			case .unsupportedPlatform:
				return "Style Sync requires Cocoa to extract styles from a Sketch file, so cannot be run on Linux."
			case .invalidArguments:
				return "Unexpected arguments. Call `stylesync -h` for help."
			case .noStylesFound:
				return "No styles found in your Sketch document. Look at https://www.sketchapp.com/docs/styling/shared-styles/ for details on how to add Shared Styles to your Sketch document."
			}
		}
	}
}
