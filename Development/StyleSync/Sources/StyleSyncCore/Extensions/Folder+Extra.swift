//
//  Folder+Extra.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 10/09/2017.
//

import Files

extension Folder {
	func file(named name: String, fileExtension: String) throws -> File {
		let fullFileName = self.fullFileName(name: name, fileExtension: fileExtension)
		return try file(named: fullFileName)
	}
	
	func createFile(named name: String, fileExtension: String) throws -> File {
		let fullFileName = self.fullFileName(name: name, fileExtension: fileExtension)
		return try createFile(named: fullFileName)
	}
	
	func createFileIfNeeded(named name: String, fileExtension: String) throws -> File {
		let fullFileName = self.fullFileName(name: name, fileExtension: fileExtension)
		return try createFileIfNeeded(withName: fullFileName)
	}
	
	private func fullFileName(name: String, fileExtension: String) -> String {
		return name + "." + fileExtension
	}
}
