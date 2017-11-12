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
		
		let firstCharacter = String(capitalizedStringWithoutSpaces.prefix(1)).lowercased()
		let otherCharacters = String(capitalizedStringWithoutSpaces.dropFirst())
		return firstCharacter + otherCharacters
	}
	
	public var lowercasedWithUnderscoreSeparators: String {
		return self
			.trimming(firstCharacter: " ")
			.trimming(firstCharacter: "-")
			.trimming(firstCharacter: "_")
			.trimming(lastCharacter: " ")
			.trimming(lastCharacter: "-")
			.trimming(lastCharacter: "_")
			.lowercased()
			.replacingOccurrences(of: " ", with: "_")
			.replacingOccurrences(of: "-", with: "_")
			.trimmingDoubleOccurences(of: "_")
	}
	
	public var capitalizedWithoutSpaceSeparators: String {
		// If the string already has no spaces, just replace illegal characters.
		guard contains(" ") else {
			return self
				.replacingOccurrences(of: "-", with: "")
				.replacingOccurrences(of: "_", with: "")
		}
		
		return self
			.trimming(firstCharacter: " ")
			.trimming(firstCharacter: "-")
			.trimming(firstCharacter: "_")
			.trimming(lastCharacter: " ")
			.trimming(lastCharacter: "-")
			.trimming(lastCharacter: "_")
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
	
	// MARK: - Helpers

	/// Removes the first character from the String if it matches the supplied
	///	Character.
	///
	/// - Parameter firstCharacter: The character to remove if it is the first
	///		character
	/// - Returns: A String with the first character removed if it matches
	///		`lastCharacter`.
	private func trimming(firstCharacter: Character) -> String {
		guard first == firstCharacter else {
			return self
		}
		return String(dropFirst())
	}
	
	/// Removes the last character from the String if it matches the supplied
	///	Character.
	///
	/// - Parameter lastCharacter: The character to remove if it is the last
	///		character
	/// - Returns: A String with the last character removed if it matches
	///		`lastCharacter`.
	private func trimming(lastCharacter: Character) -> String {
		guard last == lastCharacter else {
			return self
		}
		return String(dropLast())
	}
	
	/// Removes all double occurences of a given Character.
	///
	/// - Parameter character: The Character to remove double occurences of.
	/// - Returns: A String with double occurences of the given `character`
	///		removed.
	private func trimmingDoubleOccurences(of character: Character) -> String {
		var mutableSelf = self
		let doubleCharacter = "\(character)\(character)"
		repeat {
			mutableSelf = mutableSelf.replacingOccurrences(of: doubleCharacter, with: String(character))
		} while mutableSelf.contains(doubleCharacter)
		return mutableSelf
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
