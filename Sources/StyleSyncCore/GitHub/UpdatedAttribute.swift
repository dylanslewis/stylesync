//
//  UpdatedAttribute.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation

struct UpdatedAttribute {
	let attributeName: String
	let oldValue: String
	let newValue: String
}

extension UpdatedAttribute: CodeTemplateReplacable {
	var declarationName: String {
		return "attributeDeclaration"
	}
	
	var replacementDictionary: [String : String] {
		return [
			"attributeName": attributeName.capitalized,
			"oldValue": oldValue,
			"newValue": newValue
		]
	}
}
