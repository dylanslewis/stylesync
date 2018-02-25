//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

struct AddedStyle {
	let styleName: String
	let attributes: [AddedStyleAttribute]
	
	init(style: CodeTemplateReplacableStyle) {
		let attributes = style.replacementDictionary.keys.flatMap({ key -> AddedStyleAttribute? in
			guard let value = style.replacementDictionary[key] else {
				return nil
			}
			return .init(attributeName: key, attributeValue: value)
		})
		self.styleName = style.name
		self.attributes = attributes
	}
}

extension AddedStyle: CodeTemplateReplacable {
	var declarationName: String {
		return "styleDeclaration"
	}
	
	var replacementDictionary: [String : String] {
		return ["styleName": styleName]
	}
}
