//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
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
