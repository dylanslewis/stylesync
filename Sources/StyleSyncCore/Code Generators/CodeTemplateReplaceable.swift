//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

public protocol CodeTemplateReplacable {
	var declarationName: String { get }
	var replacementDictionary: [String: String] { get }
	var ignoredUpdateAttributes: [String] { get }
	var isDeprecated: Bool { get }
}

extension CodeTemplateReplacable {
	var ignoredUpdateAttributes: [String] {
		return []
	}
	
	var isDeprecated: Bool {
		return false
	}
}
