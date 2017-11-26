//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
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
