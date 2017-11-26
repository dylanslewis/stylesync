//
//  ScreenshotManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 29/10/2017.
//

import Foundation
import Files

class ScreenshotManager {
	// MARK: - Stored variables
	
	private var projectFolder: Folder!
	
	// MARK: - Initializer
	
	init(projectFolder: Folder) {
		self.projectFolder = projectFolder
	}
	
	// MARK: - Actions
	
	func generateScreenshots() throws {
		// TODO: Genericise the 'screenshots' part of this, so that it can easily
		// extend to other platforms
		
		// TODO: Look for other xcode projects, find the best fit.
		guard let xcodeProjectFolder = projectFolder.subfolders.first(where: { $0.extension == .xcodeProject }) else {
			// TODO: Throw
			return
		}
		// Check the project
		// TODO: Perform a better check on the project file
		let _ = try xcodeProjectFolder
			.makeFileSequence(recursive: true, includeHidden: false)
			.filter({ $0.extension == .xcodeScheme })
			.first(where: { xcodeSchemeFile in
				let xcodeSchemeXML = try xcodeSchemeFile.readAsString()
				return xcodeSchemeXML.contains("systemAttachmentLifetime = \"keepNever\"")
			})
		
		// Run the test
		// TODO: Get all these values as parameters
		let xcodeProject = XcodeProject(projectDirectory: projectFolder)
		let test = XcodeProject.Test(
			testSuite: "StyleGuideUITests",
			testCase: "StyleSyncTests",
			testName: "testSpider"
		)
		try xcodeProject.run(test: test, scheme: "StyleGuide")
		
		// Get the screenshots
		let derivedDataFolder = try Folder(path: "~/Library/Developer/Xcode/DerivedData")
		let lastUpdatedDerivedDataGroup = derivedDataFolder.subfolders
			.filter({ !$0.name.contains("ModuleCache") })
			.sorted { (lhs, rhs) -> Bool in
				return lhs.modificationDate < rhs.modificationDate
			}
			.first
		
		let attachmentsFolder = try lastUpdatedDerivedDataGroup?.subfolder(atPath: "Logs/Test/Attachments")
		attachmentsFolder?.files.forEach({ print($0.name) })
		// TODO: Show an error if these attachments aren't here
		
		// Create or checkout a StyleSyncScreenshots repository
		
	}
}
