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
	}
	
	static func log(warning: String, context: Context) {
		print("⚠️  \(warning)")
	}
	
	static func log(fatalError: Error, context: Context) -> Never {
		log(error: fatalError, context: context)
		print("\nIf you believe this is a bug, please create an issue:\n\(GitHubLink.createIssue)\n")
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
