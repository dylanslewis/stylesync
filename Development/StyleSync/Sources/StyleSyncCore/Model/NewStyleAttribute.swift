//
//  NewStyleAttribute.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 04/09/2017.
//

import Foundation

struct NewStyleAttribute {
	let attributeName: String
	let attributeValue: String
}

extension NewStyleAttribute: CodeTemplateReplacable {
	static let declarationName: String = "attributeDeclaration"
	
	var replacementDictionary: [String : String] {
		return [
			"attributeName": attributeName,
			"attributeValue": attributeValue
		]
	}
}
