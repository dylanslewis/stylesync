//
//  ErrorManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 25/10/2017.
//

import Foundation
import ShellOut

enum ErrorManager {
	static func log(error: Error, context: Context) {
		if let shellOutError = error as? ShellOutError {
			print(shellOutError.output)
			print(shellOutError.message)
		} else {
			print(error)
		}
		
		if let contextInformation = context.information {
			print(contextInformation)
		}
	}
	
	static func log(warning: String) {
		print("⚠️  \(warning)")
	}
	
	static func log(fatalError: Error, context: Context, file: String = #file, line: Int = #line) -> Never {
		print("⛔️  Fatal error at \(file):\(line) (\(context)")
		log(error: fatalError, context: context)
		print("\nIf you believe this is a bug, please create an issue on GitHub, making sure to include the error log:\n\(GitHubLink.createIssue)\n")
		exit(1)
	}
}

extension ErrorManager {
	enum Context {
		case arguments
		case questionnaire
		case config
		case files
		case sketch
		case gitHub
		case styleExtraction
		case stylesExport
		case printStyles
	}
}

extension ErrorManager.Context {
	var information: String? {
		switch self {
		case .arguments:
			return "Unexpected arguments. Call `stylesync -h` for help."
		case .config:
			return "Error finding `styleSyncConfig.json`. Make sure you run Style Sync from the root directory of your project, which should contain `styleSyncConfig.json`."
		case .sketch:
			return "Error extracting Sketch file."
		case .gitHub:
			return "Error submitting code to GitHub."
		case .styleExtraction:
			return "Error extracting styles."
		case .stylesExport:
			return "Error exporting styles."
		case .questionnaire, .files, .printStyles:
			return nil
		}
	}
}
