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
//			switch context {
//			case .printStyles where error == CodeGenerator.Error.noFileExtensionFound:
//				print("Failed to print styles")
//			default:
				print(error)
//			}
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
		case files
		case zipManager
		case projectReferenceUpdate
		case config
		case gitHub
		case sketch
		case printStyles
		case styleExtraction
		case styleExporting
	}
}
