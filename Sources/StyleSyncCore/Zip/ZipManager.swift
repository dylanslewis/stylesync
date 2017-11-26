//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files
import ShellOut

struct ZipManager {
	// MARK: - Constants
	
	private enum Constant {
		static let exportFolderName = "UnzippedSketchFiles"
		static let sketchDocumentFileName = "document.json"
	}
	
	// MARK: - Stored variables
	
	private let zippedFile: File
	private let parentFolder: Folder
	
	// MARK: - Initializer
	
	init(zippedFile: File) throws {
		guard let parentFolder = zippedFile.parent else {
			throw Error.failedToFindParentFolder(file: zippedFile)
		}
		self.zippedFile = zippedFile
		self.parentFolder = parentFolder
	}
	
	// MARK: - Actions
	
	func getSketchDocument() throws -> File {
		let exportFolder = try parentFolder.createSubfolder(named: Constant.exportFolderName)
		try shellOut(to: .unzip(zippedFile: zippedFile.path, exportDirectory: exportFolder.path))
		
		let sketchDocument = try exportFolder.file(named: Constant.sketchDocumentFileName)
		return sketchDocument
	}
	
	func cleanup() throws {
		let exportFolder = try parentFolder.subfolder(named: Constant.exportFolderName)
		try shellOut(to: .removeDirectory(directory: exportFolder.path))
	}
}

extension ZipManager {
	enum Error: Swift.Error, CustomStringConvertible {
		case failedToFindParentFolder(file: File)
		
		/// A string describing the error.
		public var description: String {
			switch self {
			case .failedToFindParentFolder(let file):
				return "Failed to find the parent folder of \(file.path)"
			}
		}
	}
}

private extension ShellOutCommand {
	static func unzip(zippedFile file: String, exportDirectory: String) -> ShellOutCommand {
		let command = "unzip \(file) -d \(exportDirectory)"
		return ShellOutCommand(string: command)
	}
}
