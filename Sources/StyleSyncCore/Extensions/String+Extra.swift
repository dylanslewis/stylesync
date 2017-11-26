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
	
	/// Finds the range of a given string, and only returns it if the
	///	`Character`s before and after the range are not contained in the given
	///	`characterSet`
	///
	/// - Parameters:
	///   - string: The `String` to find the range of.
	///   - characterSet: The `CharacterSet` to compare with.
	/// - Returns: The range of `string`.
	func range(of string: String, whereSurroundingCharactersAreNotContainedIn characterSet: CharacterSet) -> Range<Index>? {
		guard let range = self.range(of: string) else {
			return nil
		}
		
		if range.upperBound < endIndex {
			// There is a character after the range that was found.
			
			// The `upperBound` is already corresponds to the index after the
			// range.
			//
			// - SeeAlso: https://developer.apple.com/documentation/swift/range/1778545-upperbound
			let characterAfterRange = self[range.upperBound]
			
			if characterAfterRange.characterSet.isSubset(of: characterSet) {
				return nil
			}
		}
		
		if range.lowerBound > startIndex {
			// There is a character before the range that was found.
			let indexBeforeRange = index(before: range.lowerBound)
			let characterBeforeRange = self[indexBeforeRange]
			
			if characterBeforeRange.characterSet.isSubset(of: characterSet) {
				return nil
			}
		}
		
		return range
	}
}

private extension Character {
	/// Returns a `CharacterSet` contains only `self`.
	var characterSet: CharacterSet {
		return CharacterSet(charactersIn: String(self))
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
