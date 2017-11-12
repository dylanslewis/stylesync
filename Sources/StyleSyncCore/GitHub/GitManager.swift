//
//  GitManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation
import ShellOut
import Files

struct GitManager {
	// MARK: - Stored properties

	private let projectFolder: Folder
	private let filesToCommit: [File]
	private let version: Version
	var originalBranchName: String!
	
	// MARK: - Computed properties
	
	var stylesyncBranchName: String {
		return "stylesync/updateToVersion\(version.stringRepresentation)"
	}
	var projectFolderPath: String {
		return projectFolder.path
	}
	
	// MARK: - Initializer
	
	init(projectFolder: Folder, filesToCommit: [File], version: Version) throws {
		self.projectFolder = projectFolder
		self.filesToCommit = filesToCommit
		self.version = version
		originalBranchName = try shellOut(to: .gitGetCurrentBranch())
	}
	
	// MARK: - Actions
	
	func createStyleSyncBranch() throws {
		print("Creating branch '\(stylesyncBranchName)'")
		try shellOut(to: .gitCreateBranch(branch: stylesyncBranchName), at: projectFolderPath)
		
		print("Checking out branch '\(stylesyncBranchName)'")
		try shellOut(to: .gitCheckout(branch: stylesyncBranchName), at: projectFolderPath)
	}
	
	func commitAllStyleUpdates() throws {
		print("Adding files to commit:")
		print(filesToCommit.map({ $0.path }).joined(separator: "\n"))
		
		try filesToCommit
			.map({ $0.path })
			.forEach { try shellOut(to: .gitAdd(atPath: $0)) }
		
		print("Committing changes")
		try shellOut(
			to: .gitCommitWithoutAdding(message: "Update style guide to version \(version.stringRepresentation)"),
			at: projectFolderPath
		)
		
		print("Pushing changes")
		try shellOut(to: .gitInitialPush(branch: stylesyncBranchName), at: projectFolderPath)
		
		print("🎉  Successfully pushed updated style files to `origin/\(stylesyncBranchName)`")
	}
	
	func checkoutOriginalBranch() throws {
		try shellOut(to: .gitCheckout(branch: originalBranchName), at: projectFolderPath)
	}
}

private extension ShellOutCommand {
	static func gitAdd(atPath path: String) -> ShellOutCommand {
		var command = "git add"
		command.append(argument: path)
		return ShellOutCommand(string: command)
	}
	
	static func gitCommitWithoutAdding(message: String) -> ShellOutCommand {
		var command = "git commit -m"
		command.append(argument: message)
		command.append(" --quiet")
		return ShellOutCommand(string: command)
	}
	
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

extension ShellOutCommand {
	static func gitGetOriginURL() -> ShellOutCommand {
		var command = "git"
		command.append(argument: "remote")
		command.append(argument: "get-url")
		command.append(argument: "origin")
		return ShellOutCommand(string: command)
	}
}
