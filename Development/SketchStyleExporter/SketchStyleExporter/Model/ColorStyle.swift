//
//  ColorStyle.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 10/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

struct ColorStyle: CodeNameable {
	let name: String
	let identifier: String
	let color: NSColor
	
	init?(colorStyleObject: SketchDocument.ColorStyles.Object) {
		// FIXME: Check what happens with gradient styles
		guard let colorFill = colorStyleObject.value.fills.first else {
			return nil
		}
		let red = colorFill.color.red
		let green = colorFill.color.green
		let blue = colorFill.color.blue
		let alpha = colorFill.color.alpha
		
		self.name = colorStyleObject.name
		self.identifier = colorStyleObject.identifier
		self.color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
	}
}

// MARK: - CodeTemplateReplacable

extension ColorStyle: CodeTemplateReplacable {
	static let declarationName: String = "ColorDeclaration"
	
	var replacementDictionary: [String: String] {
		return [
			"name": name,
			"colorName": codeName,
			"red": String(describing: color.redComponent),
			"green": String(describing: color.greenComponent),
			"blue": String(describing: color.blueComponent),
			"alpha": String(describing: color.alphaComponent),
		]
	}
}

// MARK: - Helpers

private extension NSColor {
	var components: (CGFloat, CGFloat, CGFloat, CGFloat) {
		return ((redComponent * 255).rounded(), (greenComponent * 255).rounded(), (blueComponent * 255).rounded(), alphaComponent)
	}
}

extension ColorStyle {
	static func colorStyle(for color: NSColor, in colorStyles: [ColorStyle]) -> ColorStyle? {
		return colorStyles.first(where: { $0.color.components == color.components })
	}
}
