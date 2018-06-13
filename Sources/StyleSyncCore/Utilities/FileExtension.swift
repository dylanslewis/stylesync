//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

enum FileExtension {
	case swift
	case xml
	case markdown
	case log
	case other(type: String)
	
	init(rawValue: String) {
		switch rawValue {
		case "swift":
			self = .swift
		case "xml":
			self = .xml
		case "md":
			self = .markdown
		case "log":
			self = .log
		default:
			self = .other(type: rawValue)
		}
	}
}

enum VariableType {
	case colorStyleName
	case textStyleName
	case fontName
}

extension String {
	func codeName(_ fileExtension: FileExtension, variableType: VariableType) -> String {
		switch fileExtension {
		case .swift where variableType == .fontName:
			guard self.contains("SFUIDisplay") || self.contains("SFUIText") else {
				return self
			}
			return ".\(self)"
		case .swift:
			return self.camelcased
		case .xml:
			switch variableType {
			case .colorStyleName, .fontName:
				return self.lowercasedWithUnderscoreSeparators
			case .textStyleName:
				return self.capitalizedWithoutSpaceSeparators
			}
		case .markdown, .log:
			return self
		default:
			return self.camelcased
		}
	}
}
