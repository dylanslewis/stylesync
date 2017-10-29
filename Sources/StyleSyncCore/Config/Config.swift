//
//  Config.swift
//  StyleSync
//
//  Created by Dylan Lewis on 09/10/2017.
//

import Foundation
import Files

public class Config: Codable {
	public var sketchDocument: String!
	public var colorStyle: Style = Style()
	public var textStyle: Style = Style()
	public var gitHubPersonalAccessToken: String?
	
	public class Style: Codable {
		var template: String!
		var exportDirectory: String!
	}
}

// MARK: - Creatable

extension Config: Creatable {
	var firstQuestion: Question {
		return sketchDocumentLocation
	}
	
	private var sketchDocumentLocation: Question {
		return Question(question: "🔶 What is the relative path of your Sketch document?") { (updatedSelf, answer) -> (Config?, Question?)? in
			guard let updatedConfig = updatedSelf as? Config else {
				return nil
			}
			do {
				_ = try File(path: answer)
			} catch {
				ErrorManager.log(error: error, context: .config)
				return nil
			}
			updatedConfig.sketchDocument = answer
			return (updatedConfig, self.colorStyleTemplateLocation)
		}
	}
	
	private var colorStyleTemplateLocation: Question {
		return Question(question: "🎨 What is the relative path of your color template file?") { (updatedSelf, answer) -> (Config?, Question?)? in
			guard let updatedConfig = updatedSelf as? Config, ["", "help"].contains(answer) == false else {
				let helpMessage = "\nPlease give the relative path to your Template file.\n"
					+ "You can get a default template from \(GitHubLink.templatesDirectory)\n"
					+ "\n"
					+ "If you'd like to make your own template, check out \(GitHubLink.templateReadme)"
				print(helpMessage)
				return nil
			}
			do {
				_ = try File(path: answer)
			} catch {
				ErrorManager.log(error: error, context: .config)
				return nil
			}
			updatedConfig.colorStyle.template = answer
			return (updatedConfig, self.colorStyleExportDirectoryLocation)
		}
	}
	
	private var colorStyleExportDirectoryLocation: Question {
		return Question(question: "💅 Where would you like to export the generated color file to?") { (updatedSelf, answer) -> (Config?, Question?)? in
			guard let updatedConfig = updatedSelf as? Config else {
				return nil
			}
			do {
				_ = try Folder(path: answer)
			} catch {
				ErrorManager.log(error: error, context: .config)
				return nil
			}
			updatedConfig.colorStyle.exportDirectory = answer
			return (updatedConfig, self.textStyleTemplateLocation)
		}
	}
	
	private var textStyleTemplateLocation: Question {
		return Question(question: "✍️  What is the relative path of your text styles template file?") { (updatedSelf, answer) -> (Config?, Question?)? in
			guard let updatedConfig = updatedSelf as? Config else {
				return nil
			}
			do {
				_ = try File(path: answer)
			} catch {
				ErrorManager.log(error: error, context: .config)
				return nil
			}
			updatedConfig.textStyle.template = answer
			return (updatedConfig, self.textStyleExportDirectoryLocation)
		}
	}
	
	private var textStyleExportDirectoryLocation: Question {
		return Question(question: "💅 Where would you like to export the generated text styles file to?") { (updatedSelf, answer) -> (Config?, Question?)? in
			guard let updatedConfig = updatedSelf as? Config else {
				return nil
			}
			do {
				_ = try Folder(path: answer)
			} catch {
				ErrorManager.log(error: error, context: .config)
				return nil
			}
			updatedConfig.textStyle.exportDirectory = answer
			return (updatedConfig, self.gitHubPersonalAccessTokenQuestion)
		}
	}
	
	private var gitHubPersonalAccessTokenQuestion: Question {
		return Question(question: "If you would like Style Sync to make a branch, commit, push and raise a pull request for styling changes, please enter your GitHub personal access token. (optional)") { (updatedSelf, answer) -> (Config?, Question?)? in
			guard let updatedConfig = updatedSelf as? Config, !answer.isEmpty else {
				return (nil, nil)
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
