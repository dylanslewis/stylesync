//
//  TextStyle.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 10/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

struct TextStyle {
	let name: String
	let fontName: String
	let pointSize: CGFloat
	let kerning: CGFloat
	let lineHeight: CGFloat
	let color: NSColor
	
	init?(textStyleObject: SketchDocument.TextStyles.Object) {
		let textAttributes = textStyleObject.value.textStyle.encodedAttributes
		
		guard
			let fontName = textAttributes.font.fontName,
			let pointSize = textAttributes.font.pointSize,
			let lineHeight = textAttributes.paragraphStyle.paragraphStyle?.maximumLineHeight,
			let color = textAttributes.color.color
		else {
			return nil
		}
		
		self.name = textStyleObject.name.camelcased
		self.fontName = fontName
		self.pointSize = pointSize
		self.kerning = textAttributes.kerning
		self.lineHeight = lineHeight
		self.color = color
	}
}
