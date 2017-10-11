//
//  Config.swift
//  StyleSync
//
//  Created by Dylan Lewis on 09/10/2017.
//

import Foundation
import Files

struct Config: Codable {
	var sketchDocument: File!
	var colorStyle: Style = Style()
	var textStyle: Style = Style()
	var gitHubPersonalAccessToken: String?
	
	struct Style: Codable {
		var template: File!
		var exportDirectory: Folder!
	}
}

// MARK: - Creatable

extension Config: Creatable {
	var firstQuestion: Question {
		return sketchDocumentLocation
	}
	
	private var sketchDocumentLocation: Question {
		return Question(question: "🔶 What is the location of your Sketch document?") { (updatedSelf, answer) -> (Config, Question?)? in
			guard let answer = answer, var updatedConfig = updatedSelf as? Config else {
				return nil
			}
			let file: File
			do {
				file = try File(path: answer)
			} catch {
				print(error)
				return nil
			}
			updatedConfig.sketchDocument = file
			return (updatedConfig, self.colorStyleTemplateLocation)
		}
	}
	
	private var colorStyleTemplateLocation: Question {
		return Question(question: "🎨 What is the location of your color template file?") { (updatedSelf, answer) -> (Config, Question?)? in
			guard let answer = answer, var updatedConfig = updatedSelf as? Config else {
				return nil
			}
			let file: File
			do {
				file = try File(path: answer)
			} catch {
				print(error)
				return nil
			}
			updatedConfig.colorStyle.template = file
			return (updatedConfig, self.colorStyleExportDirectoryLocation)
		}
	}
	
	private var colorStyleExportDirectoryLocation: Question {
		return Question(question: "💅 Where would you like to export the generated color file to?") { (updatedSelf, answer) -> (Config, Question?)? in
			guard let answer = answer, var updatedConfig = updatedSelf as? Config else {
				return nil
			}
			let folder: Folder
			do {
				folder = try Folder(path: answer)
			} catch {
				print(error)
				return nil
			}
			updatedConfig.colorStyle.exportDirectory = folder
			return (updatedConfig, self.textStyleTemplateLocation)
		}
	}
	
	private var textStyleTemplateLocation: Question {
		return Question(question: "✍️ What is the location of your text styles template file?") { (updatedSelf, answer) -> (Config, Question?)? in
			guard let answer = answer, var updatedConfig = updatedSelf as? Config else {
				return nil
			}
			let file: File
			do {
				file = try File(path: answer)
			} catch {
				print(error)
				return nil
			}
			updatedConfig.textStyle.template = file
			return (updatedConfig, self.textStyleExportDirectoryLocation)
		}
	}
	
	private var textStyleExportDirectoryLocation: Question {
		return Question(question: "💅 Where would you like to export the generated text styles file to?") { (updatedSelf, answer) -> (Config, Question?)? in
			guard let answer = answer, var updatedConfig = updatedSelf as? Config else {
				return nil
			}
			let folder: Folder
			do {
				folder = try Folder(path: answer)
			} catch {
				print(error)
				return nil
			}
			updatedConfig.textStyle.exportDirectory = folder
			return (updatedConfig, self.gitHubPersonalAccessTokenQuestion)
		}
	}
	
	private var gitHubPersonalAccessTokenQuestion: Question {
		return Question(question: "If you would like Style Sync to make a branch, commit, push and raise a pull request for styling changes, please enter your GitHub personal access token. (optional)") { (updatedSelf, answer) -> (Config, Question?)? in
			guard let answer = answer, var updatedConfig = updatedSelf as? Config, !answer.isEmpty else {
				return (self, nil)
			}
			updatedConfig.gitHubPersonalAccessToken = answer
			return (updatedConfig, nil)
		}
	}
}

// MARK: - File + Codable

extension File: Codable {
	public convenience init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let path = try container.decode(String.self, forKey: .path)
		try self.init(path: path)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(path, forKey: .path)
	}
	
	enum CodingKeys: String, CodingKey {
		case path
	}
}

// MARK: - Folder + Codable

extension Folder: Codable {
	public convenience init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let path = try container.decode(String.self, forKey: .path)
		try self.init(path: path)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(path, forKey: .path)
	}
	
	enum CodingKeys: String, CodingKey {
		case path
	}
}
