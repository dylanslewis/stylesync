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
	let kerning: Float
	let fontName: String
	let pointSize: Float
	let lineHeight: CGFloat
	let color: NSColor
	let colorStyle: ColorStyle?
}
