//
//  NewStyle.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 04/09/2017.
//

import Foundation

struct NewStyle {
	let styleName: String
	let attributes: [NewStyleAttribute]
	
	init(style: Style) {
		let attributes = style.replacementDictionary.keys.flatMap({ key -> NewStyleAttribute? in
			guard let value = style.replacementDictionary[key] else {
				return nil
			}
			return .init(attributeName: key, attributeValue: value)
		})
		self.styleName = style.codeName
		self.attributes = attributes
	}
}

extension NewStyle: CodeTemplateReplacable {
	static let declarationName: String = "styleDeclaration"
	
	var replacementDictionary: [String : String] {
		return ["styleName": styleName]
	}
}
