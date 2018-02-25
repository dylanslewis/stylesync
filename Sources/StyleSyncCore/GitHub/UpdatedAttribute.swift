//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
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
