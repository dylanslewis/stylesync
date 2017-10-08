//
//  RemovedStyle.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 07/09/2017.
//

import Foundation

struct RemovedStyle {
	let styleName: String
	
	init(style: CodeTemplateReplacableStyle) {
		self.styleName = style.name
	}
}

extension RemovedStyle: CodeTemplateReplacable {
	var declarationName: String {
		return "styleDeclaration"
	}
	
	var replacementDictionary: [String : String] {
		return ["styleName": styleName]
	}
}
