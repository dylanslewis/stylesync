//
//  UpdatedStyle.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation

struct UpdatedStyle {
	let styleName: String
	let updatedAttributes: [UpdatedAttribute]
	
	init?(oldStyle: Style & CodeTemplateReplacable, newStyle: Style & CodeTemplateReplacable) {
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
		
		self.styleName = newStyle.codeName
		self.updatedAttributes = updatedOldStyleAttributes.flatMap { (key, oldValue) in
			guard let newValue = updatedNewStyleAttributes[key] else {
				return nil
			}
			return .init(attributeName: key, oldValue: oldValue, newValue: newValue)
		}
	}
}
