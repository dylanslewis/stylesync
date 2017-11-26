//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
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
