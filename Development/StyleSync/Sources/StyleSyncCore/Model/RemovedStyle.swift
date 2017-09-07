//
//  RemovedStyle.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 07/09/2017.
//

import Foundation

struct RemovedStyle {
	let styleName: String
	
	init(style: Style) {
		self.styleName = style.name
	}
}

extension RemovedStyle: CodeTemplateReplacable {
	static let declarationName: String = "styleDeclaration"
	
	var replacementDictionary: [String : String] {
		return ["styleName": styleName]
	}
}
