//
//  TextStyle.swift
//  StyleSync
//
//  Created by Dylan Lewis on 10/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

struct TextStyle: Style, Codable {
	let name: String
	let identifier: String
	let fontName: String
	let pointSize: CGFloat
	let kerning: CGFloat
	let lineHeight: CGFloat
	let colorStyle: ColorStyle
	let isDeprecated: Bool
	
	init(
		name: String,
		identifier: String,
		fontName: String,
		pointSize: CGFloat,
		kerning: CGFloat,
		lineHeight: CGFloat,
		colorStyle: ColorStyle,
		isDeprecated: Bool
	) {
		self.name = name
		self.identifier = identifier
		self.fontName = fontName
		self.pointSize = pointSize
		self.kerning = kerning
		self.lineHeight = lineHeight
		self.colorStyle = colorStyle
		self.isDeprecated = isDeprecated
	}
	
	init?(textStyleObject: SketchDocument.TextStyles.Object, colorStyle: ColorStyle, isDeprecated: Bool = false) {
		let textAttributes = textStyleObject.value.textStyle.encodedAttributes
		guard
			let fontName = textAttributes.font.fontName,
			let pointSize = textAttributes.font.pointSize,
			let lineHeight = textAttributes.paragraphStyle.paragraphStyle?.maximumLineHeight
		else {
			return nil
		}
		
		self.name = textStyleObject.name
		self.identifier = textStyleObject.identifier
		self.fontName = fontName
		self.pointSize = pointSize.roundedToTwoDecimalPlaces
		self.kerning = textAttributes.kerning.roundedToTwoDecimalPlaces
		self.lineHeight = lineHeight.roundedToTwoDecimalPlaces
		self.colorStyle = colorStyle
		self.isDeprecated = isDeprecated
	}
}

// MARK: - Equatable

extension TextStyle: Equatable {
	static func == (lhs: TextStyle, rhs: TextStyle) -> Bool {
		return
			lhs.name == rhs.name &&
			lhs.identifier == rhs.identifier &&
			lhs.fontName == rhs.fontName &&
			lhs.pointSize == rhs.pointSize &&
			lhs.kerning == rhs.kerning &&
			lhs.lineHeight == rhs.lineHeight &&
			lhs.colorStyle == rhs.colorStyle &&
			lhs.isDeprecated == rhs.isDeprecated
	}
}

// MARK: - Hashable

extension TextStyle: Hashable {
	var hashValue: Int {
		return
			name.hashValue ^
			identifier.hashValue ^
			fontName.hashValue ^
			pointSize.hashValue ^
			kerning.hashValue ^
			lineHeight.hashValue ^
			colorStyle.hashValue ^
			isDeprecated.hashValue
	}
}

// MARK: - CodeTemplateReplacable

extension TextStyle: CodeTemplateReplacable {
	static let declarationName: String = "textStyleDeclaration"
	
	var replacementDictionary: [String: String] {
		let exportFontName: String
		if fontName.contains("SFUIDisplay") || fontName.contains("SFUIText") {
			exportFontName = ".\(fontName)"
		} else {
			exportFontName = fontName
		}
		return [
			"name": name,
			"textStyleName": codeName,
			"fontName": "\"\(exportFontName)\"",
			"pointSize": String(describing: pointSize),
			"kerning": String(describing: kerning),
			"lineHeight": String(describing: lineHeight),
			"color": ".\(colorStyle.codeName)"
		]
	}
}

// MARK: - Deprecatable

extension TextStyle {
	var deprecated: Style {
		return TextStyle(
			name: name,
			identifier: identifier,
			fontName: fontName,
			pointSize: pointSize,
			kerning: kerning,
			lineHeight: lineHeight,
			colorStyle: colorStyle,
			isDeprecated: true
		)
	}
}
