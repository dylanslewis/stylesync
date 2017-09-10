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
	
	func unarchivedObject<TargetObjectType>() -> TargetObjectType? {
		guard let data = Data(base64Encoded: self) else {
			return nil
		}
		return NSKeyedUnarchiver.unarchiveObject(with: data) as? TargetObjectType
	}
	
	init(contentsOfURL url: URL, encoding: String.Encoding = .utf8) throws {
		let data = try Data(contentsOf: url)
		guard let string = String(data: data, encoding: encoding) else {
			throw Error.failedToCreateStringFromData
		}
		self = string
	}
	
	enum Error: Swift.Error {
		case failedToCreateStringFromData
	}
}
