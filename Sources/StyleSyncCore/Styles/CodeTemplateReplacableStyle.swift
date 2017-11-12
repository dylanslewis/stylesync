//
//  CodeTemplateReplacableStyle.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 08/10/2017.
//

import Foundation

struct CodeTemplateReplacableStyle: CodeTemplateReplacable {
	var style: Style
	var declarationName: String
	var replacementDictionary: [String : String]
	var ignoredUpdateAttributes: [String]
	var isDeprecated: Bool
	
	var variableName: String
	var name: String {
		return style.name
	}
	var identifier: String {
		return style.identifier
	}
	
	init(textStyle: TextStyle, fileType: FileType) {
		let fileExtension = FileExtension(rawValue: fileType)
		let letterSpacingEm = textStyle.kerning / textStyle.pointSize
		let lineSpacingExtra = textStyle.lineHeight - textStyle.pointSize
		let lineSpacingMultiplier = (textStyle.lineHeight / textStyle.pointSize).rounded(toPlaces: 2)
		
		self.variableName = textStyle.name.codeName(fileExtension, variableType: .textStyleName)
		self.style = textStyle
		self.declarationName = "textStyleDeclaration"
		self.replacementDictionary = [
			"name": textStyle.name,
			"textStyleName": self.variableName,
			"fontName": textStyle.fontName.codeName(fileExtension, variableType: .fontName),
			"pointSize": textStyle.pointSize.cleaned,
			"kerning": String(describing: textStyle.kerning),
			"letterSpacingEm": String(describing: letterSpacingEm.roundedToTwoDecimalPlaces),
			"lineHeight": textStyle.lineHeight.cleaned,
			"lineSpacingExtra": lineSpacingExtra.cleaned,
			"lineSpacingMultiplier": String(describing: lineSpacingMultiplier),
			"color": textStyle.colorStyle.name.codeName(fileExtension, variableType: .colorStyleName)
		]
		self.ignoredUpdateAttributes = ["letterSpacingEm", "lineSpacingExtra", "lineSpacingMultiplier"]
		self.isDeprecated = textStyle.isDeprecated
	}
	
	init(colorStyle: ColorStyle, fileType: FileType) {
		let fileExtension = FileExtension(rawValue: fileType)
		
		self.variableName = colorStyle.name.codeName(fileExtension, variableType: .colorStyleName)
		self.style = colorStyle
		self.declarationName = "colorDeclaration"
		self.replacementDictionary = [
			"name": colorStyle.name,
			"colorName": self.variableName,
			"red": String(describing: colorStyle.color.components.red),
			"green": String(describing: colorStyle.color.components.green),
			"blue": String(describing: colorStyle.color.components.blue),
			"alpha": String(describing: colorStyle.color.components.alpha),
			"hex": colorStyle.color.hex
		]
		self.ignoredUpdateAttributes = ["red", "green", "blue", "alpha"]
		self.isDeprecated = colorStyle.isDeprecated
	}
}

extension CodeTemplateReplacableStyle: Hashable {
	static func == (lhs: CodeTemplateReplacableStyle, rhs: CodeTemplateReplacableStyle) -> Bool {
		return
			lhs.declarationName == rhs.declarationName &&
				lhs.replacementDictionary == rhs.replacementDictionary &&
				lhs.ignoredUpdateAttributes == rhs.ignoredUpdateAttributes &&
				lhs.isDeprecated == rhs.isDeprecated
	}
	
	var hashValue: Int {
		if let textStyle = style as? TextStyle {
			return textStyle.hashValue
		} else if let colorStyle = style as? ColorStyle {
			return colorStyle.hashValue
		} else {
			fatalError("Unknown Style type")
		}
	}
}

private extension CGFloat {
	var cleaned: String {
		return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(describing: self.roundedToTwoDecimalPlaces)
	}
}

private enum FileExtension {
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

private enum VariableType {
	case colorStyleName
	case textStyleName
	case fontName
}

private extension String {
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
