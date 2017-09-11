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
		originalBranchName = try shellOut(to: .gitGetCurrentBranch())
	}
	
	// MARK: - Actions
	
	func createStyleSyncBranch() throws {
		// FIXME: Don't cd, use path parameter
		try shellOut(to: .changeDirectory(directory: projectFolderPath))
		try shellOut(to: .gitCreateBranch(branch: styleSyncBranchName))
		try shellOut(to: .gitCheckout(branch: styleSyncBranchName))
	}
	
	func commitAllStyleUpdates() throws {
		try shellOut(to: .gitCommit(message: "Update style guide to version \(version.stringRepresentation)"))
		try shellOut(to: .gitInitialPush(branch: styleSyncBranchName))
	}
	
	func checkoutOriginalBranch() throws {
		try shellOut(to: .gitCheckout(branch: originalBranchName))
	}
}

private extension ShellOutCommand {
	static func gitGetCurrentBranch() -> ShellOutCommand {
		var command = "git"
		command.append(argument: "describe")
		command.append(argument: "--contains")
		command.append(argument: "--all")
		command.append(argument: "HEAD")
		return ShellOutCommand(string: command)
	}
	
	static func gitCreateBranch(branch: String) -> ShellOutCommand {
		var command = "git"
		command.append(argument: "branch")
		command.append(argument: branch)
		return ShellOutCommand(string: command)
	}
	
	static func gitInitialPush(branch: String) -> ShellOutCommand {
		var command = "git"
		command.append(argument: "push")
		command.append(argument: "--set-upstream")
		command.append(argument: "origin")
		command.append(argument: branch)
		return ShellOutCommand(string: command)
	}
}
