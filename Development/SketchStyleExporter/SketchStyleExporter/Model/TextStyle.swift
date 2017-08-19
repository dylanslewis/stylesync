//
//  TextStyle.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 10/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

struct TextStyle: Codable, CodeNameable {
	let name: String
	let identifier: String
	let fontName: String
	let pointSize: CGFloat
	let kerning: CGFloat
	let lineHeight: CGFloat
	let colorStyle: ColorStyle
	
	init?(textStyleObject: SketchDocument.TextStyles.Object, colorStyle: ColorStyle) {
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
		self.pointSize = pointSize
		self.kerning = textAttributes.kerning
		self.lineHeight = lineHeight
		self.colorStyle = colorStyle
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
			lhs.colorStyle == rhs.colorStyle
	}
}

// MARK: - CodeTemplateReplacable

extension TextStyle: CodeTemplateReplacable {
	static let declarationName: String = "TextStyleDeclaration"
	
	var replacementDictionary: [String: String] {
		return [
			"name": name,
			"textStyleName": codeName,
			"fontName": "\".\(fontName)\"", // TODO: Only do this for SF
			"pointSize": String(describing: pointSize),
			"kerning": String(describing: kerning),
			"lineHeight": String(describing: lineHeight),
			"color": ".\(colorStyle.codeName)"
		]
	}
}
