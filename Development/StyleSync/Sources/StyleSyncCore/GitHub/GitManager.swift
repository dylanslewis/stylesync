//
//  GitManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation
import ShellOut

struct GitManager {
	// MARK: - Stored properties
	
	private let projectFolderPath: String
	private let version: Version
	var originalBranchName: String!
	
	// MARK: - Computed properties
	
	var styleSyncBranchName: String {
		return "styleSync/updateToVersion\(version.stringRepresentation)"
	}
	
	// MARK: - Initializer
	
	init(projectFolderPath: String, version: Version) throws {
		self.projectFolderPath = projectFolderPath
		self.version = version
		originalBranchName = try shellOut(to: .getGitBranch())
	}
	
	// MARK: - Actions
	
	func createStyleSyncBranch() throws {
		try shellOut(to: .changeDirectory(directory: projectFolderPath))
		try shellOut(to: .gitCheckout(branch: styleSyncBranchName))
	}
	
	func commitAllStyleUpdates() throws {
		try shellOut(to: .gitCommit(message: "Update style guide to version \(version.stringRepresentation)"))
		try shellOut(to: .gitPush(branch: styleSyncBranchName))
	}
	
	func checkoutOriginalBranch() throws {
		try shellOut(to: .gitCheckout(branch: originalBranchName))
	}
}

private extension ShellOutCommand {
	static func getGitBranch() -> ShellOutCommand {
		var command = "git"
		command.append(argument: "describe")
		command.append(argument: "--contains")
		command.append(argument: "--all")
		command.append(argument: "HEAD")
		return ShellOutCommand(string: command)
	}
	
	static func changeDirectory(directory: String) -> ShellOutCommand {
		var command = "cd"
		command.append(argument: directory)
		return ShellOutCommand(string: command)
	}
}

/// Copied from ShellOut.swift
private extension String {
	func appending(argument: String) -> String {
		return "\(self) \"\(argument)\""
	}
	
	func appending(arguments: [String]) -> String {
		return appending(argument: arguments.joined(separator: "\" \""))
	}
	
	mutating func append(argument: String) {
		self = appending(argument: argument)
	}
	
	mutating func append(arguments: [String]) {
		self = appending(arguments: arguments)
	}
}
