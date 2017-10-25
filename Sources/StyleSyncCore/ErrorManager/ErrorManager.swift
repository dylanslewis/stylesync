//
//  ErrorManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 25/10/2017.
//

import Foundation
import ShellOut

enum ErrorManager {
	static func log(error: Error, context: Context, isFatal: Bool = false) {
		if let shellOutError = error as? ShellOutError {
			print(shellOutError.message)
		} else {
			print(error)
		}
		
		guard isFatal else {
			return
		}
		print("If you believe this is a bug, please create an issue:\n\(GitHubLink.createIssue)")
	}
}

extension ErrorManager {
	enum Context {
		case zipManager
		case projectReferenceUpdate
		case config
		case gitHubPullRequest
	}
}
