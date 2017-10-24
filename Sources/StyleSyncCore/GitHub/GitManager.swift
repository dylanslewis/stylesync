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
	private let exportTextFolderPath: String
	private let exportColorsFolderPath: String
	private let exportedTextFileNames: [String]
	private let exportedColorsFileNames: [String]
	private let version: Version
	var originalBranchName: String!
	
	// MARK: - Computed properties
	
	var styleSyncBranchName: String {
		return "styleSync/updateToVersion\(version.stringRepresentation)"
	}
	
	// MARK: - Initializer
	
	init(
		projectFolderPath: String,
		exportTextFolderPath: String,
		exportColorsFolderPath: String,
		exportedTextFileNames: [String],
		exportedColorsFileNames: [String],
		version: Version
	) throws {
		self.projectFolderPath = projectFolderPath
		self.exportTextFolderPath = exportTextFolderPath
		self.exportColorsFolderPath = exportColorsFolderPath
		self.exportedTextFileNames = exportedTextFileNames
		self.exportedColorsFileNames = exportedColorsFileNames
		self.version = version
		originalBranchName = try shellOut(to: .gitGetCurrentBranch())
	}
	
	// MARK: - Actions
	
	func createStyleSyncBranch() throws {
		try shellOut(to: .gitCreateBranch(branch: styleSyncBranchName), at: projectFolderPath)
		try shellOut(to: .gitCheckout(branch: styleSyncBranchName), at: projectFolderPath)
	}
	
	func commitAllStyleUpdates() throws {
		try exportedTextFileNames.forEach { try shellOut(to: .gitAdd(atPath: $0), at: exportTextFolderPath) }
		try exportedColorsFileNames.forEach { try shellOut(to: .gitAdd(atPath: $0), at: exportColorsFolderPath) }
		
		try shellOut(
			to: .gitCommitWithoutAdding(message: "Update style guide to version \(version.stringRepresentation)"),
			at: projectFolderPath
		)
		try shellOut(to: .gitInitialPush(branch: styleSyncBranchName), at: projectFolderPath)
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
		var command = "git commit -a -m"
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
