//
//  DeprecatedStyle.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 07/09/2017.
//

import Foundation

struct DeprecatedStyle {
	let styleName: String
	let fileNames: [String]
}

extension DeprecatedStyle: CodeTemplateReplacable {
	var declarationName: String {
		return "styleDeclaration"
	}
	
	var replacementDictionary: [String : String] {
		let allFileNames = fileNames
			.map({ "`" + $0 + "`" })
			.joined(separator: " ")
		return [
			"styleName": styleName,
			"fileNames": allFileNames
		]
	}
}
