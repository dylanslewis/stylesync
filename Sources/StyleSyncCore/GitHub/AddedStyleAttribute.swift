//
//  AddedStyleAttribute.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 04/09/2017.
//

import Foundation

struct AddedStyleAttribute {
	let attributeName: String
	let attributeValue: String
}

extension AddedStyleAttribute: CodeTemplateReplacable {
	var declarationName: String {
		return "attributeDeclaration"
	}
	
	var replacementDictionary: [String : String] {
		return [
			"attributeName": attributeName,
			"attributeValue": attributeValue
		]
	}
}
