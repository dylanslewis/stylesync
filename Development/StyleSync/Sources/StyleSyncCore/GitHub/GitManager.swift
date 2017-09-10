//
//  GitManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation

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
	
	init(projectFolderPath: String, version: Version) {
		self.projectFolderPath = projectFolderPath
		self.version = version
		originalBranchName = bash(command: "git", arguments: ["describe", "--contains", "--all", "HEAD"])
	}
	
	// MARK: - Actions
	
	func createStyleSyncBranch() {
		bash(command: "cd", arguments: [projectFolderPath])
		bash(command: "git", arguments: ["branch", styleSyncBranchName])
		bash(command: "git", arguments: ["checkout", styleSyncBranchName])
	}
	
	func commitAllStyleUpdates() {
		bash(command: "git", arguments: ["add", "\(projectFolderPath)/*"])
		bash(command: "git", arguments: ["commit", "-m", "Update style guide to version \(version.stringRepresentation)"])
		bash(command: "git", arguments: ["push", "--set-upstream", "origin", styleSyncBranchName])
	}
	
	func checkoutOriginalBranch() {
		bash(command: "git", arguments: ["checkout", originalBranchName])
	}
	
	// MARK: - Helpers
	
	private func shell(launchPath: String, arguments: [String]) -> String {
		let task = Process()
		task.launchPath = launchPath
		task.arguments = arguments
		
		let pipe = Pipe()
		task.standardOutput = pipe
		task.launch()
		
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(data: data, encoding: String.Encoding.utf8)!
		if output.characters.count > 0 {
			//remove newline character.
			let lastIndex = output.index(before: output.endIndex)
			return String(output[output.startIndex ..< lastIndex])
		}
		return output
	}
	
	@discardableResult
	private func bash(command: String, arguments: [String] = []) -> String {
		let whichPathForCommand = shell(launchPath: "/bin/bash", arguments: [ "-l", "-c", "which \(command)" ])
		return shell(launchPath: whichPathForCommand, arguments: arguments)
	}
}
