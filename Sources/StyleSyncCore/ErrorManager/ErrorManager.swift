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
			print("\n" + contextInformation)
		}
	}
	
	static func log(warning: String, isBug: Bool = false) {
		print("⚠️  \(warning)")
		
		if isBug {
			print("\n🙏  Please file a bug at \(GitHubLink.createIssue), making sure to include the warning log\n")
		}
	}
	
	static func log(fatalError: Error, context: Context, file: String = #file, line: Int = #line) -> Never {
		var fileName: String?
		if let fileNameSubstring = file.split(separator: "/").last {
			fileName = String(fileNameSubstring)
		}
		print("\n⛔️  Fatal error at \(fileName ?? file):\(line) (\(context))")
		log(error: fatalError, context: context)
		print("\nIf you believe this is a bug, please create an issue on GitHub at \(GitHubLink.createIssue), making sure to include the error log\n")
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
		case .config:
			return "Error finding `stylesyncConfig.json`. Make sure you run Style Sync from the root directory of your project, which should contain `stylesyncConfig.json`."
		case .sketch:
			return "Error extracting Sketch file."
		case .gitHub:
			return "Error submitting code to GitHub."
		case .styleExtraction:
			return "Error extracting styles."
		case .stylesExport:
			return "Error exporting styles."
		case .arguments, .questionnaire, .files, .printStyles:
			return nil
		}
	}
}
