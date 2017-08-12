//
//  ColorStyle.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 10/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

struct ColorStyle {
	let name: String
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
		
		self.name = colorStyleObject.name.camelcased
		self.color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
	}
}
