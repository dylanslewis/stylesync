//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

struct UpdatedStyle {
	let styleName: String
	let updatedAttributes: [UpdatedAttribute]
	
	init?(oldStyle: CodeTemplateReplacableStyle, newStyle: CodeTemplateReplacableStyle) {
		var updatedKeys: [String] = []
		let oldStyleReplacementDictionary = oldStyle.replacementDictionary
		let newStyleReplacementDictionary = newStyle.replacementDictionary
		oldStyleReplacementDictionary.forEach { (key, value) in
			if newStyleReplacementDictionary[key] != value && !newStyle.ignoredUpdateAttributes.contains(key) {
				updatedKeys.append(key)
			}
		}
		
		guard !updatedKeys.isEmpty else {
			return nil
		}
		
		let updatedOldStyleAttributes = oldStyleReplacementDictionary
			.filter({ updatedKeys.contains($0.key) })
		let updatedNewStyleAttributes = newStyleReplacementDictionary
			.filter({ updatedKeys.contains($0.key) })
		
		self.styleName = newStyle.name
		self.updatedAttributes = updatedOldStyleAttributes.compactMap { (key, oldValue) in
			guard let newValue = updatedNewStyleAttributes[key] else {
				return nil
			}
			return .init(attributeName: key, oldValue: oldValue, newValue: newValue)
		}
	}
}

extension UpdatedStyle: CodeTemplateReplacable {
	var declarationName: String {
		return "styleDeclaration"
	}
	
	var replacementDictionary: [String : String] {
		return ["styleName": styleName]
	}
}
