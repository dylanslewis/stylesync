//
//  String+Extra.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

extension String {
	var camelcased: String {
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
}
