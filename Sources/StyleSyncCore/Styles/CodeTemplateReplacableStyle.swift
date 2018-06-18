//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
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
	
	func isTheSameStyle(as codeTemplateReplaceableStyle: CodeTemplateReplacableStyle) -> Bool {
		return style.isTheSameStyle(as: codeTemplateReplaceableStyle.style)
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
			"color": textStyle.colorStyle?.name.codeName(fileExtension, variableType: .colorStyleName) ?? "NO COLOR"
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
