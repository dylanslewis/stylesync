//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files

class ConfigManager {
	// MARK: - Constants
	
	private enum Constant {
		enum Config {
			static let fileName = "stylesyncConfig"
			static let fileType: FileType = .json
		}
	}
	
	// MARK: - Stored variables
	
	private var projectFolder: Folder
	
	// MARK: - Initializer
	
	init(projectFolder: Folder) {
		self.projectFolder = projectFolder
	}
	
	// MARK: - Actions
	
	func getConfig() throws -> Config {
		do {
			return try readConfig()
		} catch File.Error.readFailed {
			return try createConfig()
		} catch {
			throw error
		}
	}
	
	// MARK: - Helpers
	
	private func readConfig() throws -> Config {
		guard let configFile = try? projectFolder.file(
			named: Constant.Config.fileName,
			fileExtension: Constant.Config.fileType
		) else {
			throw File.Error.readFailed
		}
		return try configFile.readAsDecodedJSON()
	}
	
	private func createConfig() throws -> Config {
		let questionaire = Questionaire(creatable: Config()) { (creatable) in
			guard let completedConfig = creatable as? Config else {
				return
			}
			do {
				try self.save(config: completedConfig)
			} catch {
				ErrorManager.log(error: error, context: .files)
			}
		}
		questionaire.startQuestionaire()
		return try readConfig()
	}
	
	private func save(config: Config) throws {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		
		let configFileData = try encoder.encode(config)
		guard let configFileString = String(data: configFileData, encoding: .utf8) else {
			throw File.Error.writeFailed
		}
		
		let stylesyncConfig = try projectFolder.createFileIfNeeded(
			named: Constant.Config.fileName,
			fileExtension: Constant.Config.fileType
		)
		try stylesyncConfig.write(string: configFileString)
	}
}
