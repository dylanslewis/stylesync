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
	var colorStyle: Style!
	var textStyle: Style!
	var projectDirectory: Folder?
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
	
	var sketchDocumentLocation: Question {
		return Question(
			question: "What is the location of your Sketch document?"
		) { answer -> (Config, Question?) in
			guard let file = try? File(path: answer) else {
				return (self, self.sketchDocumentLocation)
			}
			var mutableSelf = self
			mutableSelf.sketchDocument = file
			return (mutableSelf, nil)
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
