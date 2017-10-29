//
//  GitHubManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 29/10/2017.
//

import Foundation
import Files
import ShellOut

class GitHubManager {
	// MARK: - Stored variables
	
	private var projectFolder: Folder
	private var fileNamesForDeprecatedStyleNames: [String: [String]]
	
	private var username: String
	private var repositoryName: String
	
	private var version: Version
	private var personalAccessToken: String
	
	// MARK: - Initializer
	
	init(
		projectFolder: Folder,
		fileNamesForDeprecatedStyleNames: [String: [String]],
		version: Version,
		personalAccessToken: String
	) throws {
		self.projectFolder = projectFolder
		self.fileNamesForDeprecatedStyleNames = fileNamesForDeprecatedStyleNames
		self.version = version
		self.personalAccessToken = personalAccessToken
		(self.username, self.repositoryName) = try GitHubManager.getGitHubUsernameAndRepositoryName()
	}
	
	// MARK: - Actions
	
	func createBranchAndCommitChangesAndSubmitPullRequest(
		filesToCommit: [File],
		oldTextStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle],
		oldColorStyles: [CodeTemplateReplacableStyle],
		newColorStyles: [CodeTemplateReplacableStyle]
	) throws {
		let (headBranchName, baseBranchName) = try createBranchAndCommitChanges(filesToCommit: filesToCommit)
		
		try submitPullRequest(
			headBranchName: headBranchName,
			baseBranchName: baseBranchName,
			oldTextStyles: oldColorStyles,
			newTextStyles: newTextStyles,
			oldColorStyles: oldColorStyles,
			newColorStyles: newColorStyles
		)
	}
	
	// MARK: - Helpers
	
	private static func getGitHubUsernameAndRepositoryName() throws -> (username: String, repositoryName: String) {
		let shellOutput = try shellOut(to: .gitGetOriginURL())
		guard
			shellOutput.contains("git@github.com"),
			let userNameAndRepositoryName = shellOutput.split(separator: ":").last?.split(separator: "/"),
			userNameAndRepositoryName.count == 2,
			let username = userNameAndRepositoryName.first,
			let repositoryName = userNameAndRepositoryName.last
		else {
			throw Error.unexpectedConsoleOutput
		}
		return (String(username), String(repositoryName))
	}
	
	private func createBranchAndCommitChanges(
		filesToCommit: [File]
	) throws -> (headBranchName: String, baseBranchName: String) {
		let gitManager = try GitManager(
			projectFolder: projectFolder,
			filesToCommit: filesToCommit,
			version: version
		)
		
		try gitManager.createStyleSyncBranch()
		try gitManager.commitAllStyleUpdates()
		try gitManager.checkoutOriginalBranch()
		return (gitManager.styleSyncBranchName, gitManager.originalBranchName)
	}
	
	private func submitPullRequest(
		headBranchName: String,
		baseBranchName: String,
		oldTextStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle],
		oldColorStyles: [CodeTemplateReplacableStyle],
		newColorStyles: [CodeTemplateReplacableStyle]
	) throws {
		print("Submitting pull request")
		
		let pullRequestManager = GitHubPullRequestManager(
			username: username,
			repositoryName: repositoryName,
			personalAccessToken: personalAccessToken
		)
		
		let pullRequestBodyGenerator = try StyleUpdateSummaryGenerator(
			headingTemplate: GitHubTemplate.heading,
			styleNameTemplate: GitHubTemplate.styleName,
			addedStyleTableTemplate: GitHubTemplate.newStyleTable,
			updatedStyleTableTemplate: GitHubTemplate.updatedStylesTable,
			deprecatedStylesTableTemplate: GitHubTemplate.deprecatedStylesTable
		)
		
		let body = pullRequestBodyGenerator.body(
			fromOldColorStyles: oldColorStyles,
			newColorStyles: newColorStyles,
			oldTextStyles: oldTextStyles,
			newTextStyles: newTextStyles,
			fileNamesForDeprecatedStyleNames: fileNamesForDeprecatedStyleNames
		)
		
		let pullRequest = GitHub.PullRequest(
			title: "[StyleSync] Update style guide to version \(version.stringRepresentation)",
			body: body,
			head: headBranchName,
			base: baseBranchName
		)
		
		try pullRequestManager.submit(pullRequest: pullRequest)
	}
}

extension GitHubManager {
	enum Error: Swift.Error {
		case unexpectedConsoleOutput
	}
}
