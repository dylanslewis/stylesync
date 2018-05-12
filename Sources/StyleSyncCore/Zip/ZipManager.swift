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
		static let sketchMetadataFileName = "meta.json"
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
	
	func getSketchMetadata() throws -> File {
		let folder = try rawSketchFilesDirectory()
		return try folder.file(named: Constant.sketchMetadataFileName)
	}
	
	func getSketchDocument() throws -> File {
		let folder = try rawSketchFilesDirectory()
		return try folder.file(named: Constant.sketchDocumentFileName)
	}
	
	func cleanup() throws {
		let exportFolder = try parentFolder.subfolder(named: Constant.exportFolderName)
		try shellOut(to: .removeDirectory(directory: exportFolder.path))
	}
	
	// MARK: - Helpers
	
	private func rawSketchFilesDirectory() throws -> Folder {
		let exportFolder: Folder
		do {
			exportFolder = try parentFolder.subfolder(named: Constant.exportFolderName)
		} catch {
			exportFolder = try parentFolder.createSubfolder(named: Constant.exportFolderName)
		}
		if exportFolder.files.count == 0 {
			try shellOut(to: .unzip(zippedFile: zippedFile.path, exportDirectory: exportFolder.path))
		}
		return exportFolder
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
