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
		print("If you believe this is a bug, please create an issue:\n\(GitHubLink.createIssue)")
		exit(1)
	}
}

extension ErrorManager {
	enum Context {
		case zipManager
		case projectReferenceUpdate
		case config
		case gitHubPullRequest
		case sketch
		case styleExtraction
		case styleGeneration
	}
}
