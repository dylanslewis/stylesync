//
//  String+Extra.swift
//  StyleSync
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

public extension String {
	public var camelcased: String {
		let capitalizedStringWithoutSpaces: String
		if contains(" ") {
			let words = components(separatedBy: " ")
			capitalizedStringWithoutSpaces = words.map({ $0.capitalized }).joined()
		} else {
			capitalizedStringWithoutSpaces = self
		}
		
		let firstCharacter = String(capitalizedStringWithoutSpaces.characters.prefix(1)).lowercased()
		let otherCharacters = String(capitalizedStringWithoutSpaces.characters.dropFirst())
		return firstCharacter + otherCharacters
	}
	
	public var lowercasedWithUnderscoreSeparators: String {
		return self
			.lowercased()
			.replacingOccurrences(of: " ", with: "_")
			.replacingOccurrences(of: "-", with: "_")
	}
	
	public var capitalizedWithoutSpaceSeparators: String {
		return self
			.capitalized
			.replacingOccurrences(of: " ", with: "")
			.replacingOccurrences(of: "-", with: "")
			.replacingOccurrences(of: "_", with: "")
	}
	
	func unarchivedObject<TargetObjectType>() -> TargetObjectType? {
		guard let data = Data(base64Encoded: self) else {
			return nil
		}
		return NSKeyedUnarchiver.unarchiveObject(with: data) as? TargetObjectType
	}
}

/// Copied from ShellOut.swift
extension String {
	func appending(argument: String) -> String {
		return "\(self) \"\(argument)\""
	}
	
	mutating func append(argument: String) {
		self = appending(argument: argument)
	}

	func appending(parameter: String) -> String {
		return "\(self) \(parameter)"
	}
	
	mutating func append(parameter: String) {
		self = appending(parameter: parameter)
	}
}
