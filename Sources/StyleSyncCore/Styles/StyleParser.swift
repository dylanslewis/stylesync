//
//  StyleParser.swift
//  StyleSync
//
//  Created by Dylan Lewis on 23/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

struct StyleParser<S: Style> {
	var newStyles: [S]
	var currentStyles: [S]
	var deprecatedStyles: [S] {
		return currentStyles.filter { style -> Bool in
			return newStyles.contains(where: { $0.identifier == style.identifier }) == false
		}
		.map({ $0.deprecated })
		.flatMap({ $0 as? S })
	}
	
	var currentAndMigratedStyles: [(currentStyle: S, migratedStyle: S)] {
		return currentStyles
			.flatMap { style -> (S, S)? in
				guard
					let migratedStyle = newStyles.first(where: { $0.identifier == style.identifier && $0.name != style.name })
				else {
					return nil
				}
				return (style, migratedStyle)
		}
	}
}

extension StyleParser where S == ColorStyle {
	init(sketchDocument: SketchDocument, previousStyles: [S]?) {
		self.newStyles = sketchDocument.layerStyles.objects
			.flatMap({ ColorStyle(colorStyleObject: $0) })
		self.currentStyles = previousStyles ?? []
	}
}

extension StyleParser where S == TextStyle {
	init(sketchDocument: SketchDocument, colorStyles: [ColorStyle], previousStyles: [S]?) {
		self.newStyles = sketchDocument.layerTextStyles.objects
			.flatMap { textStyleObject -> TextStyle? in
				guard
					let color = textStyleObject.value.textStyle.encodedAttributes.color.color,
					let colorStyle = ColorStyle.colorStyle(for: color, in: colorStyles)
				else {
					print("⚠️ \(textStyleObject.name) does not use a color from the shared colour scheme")
					return nil
				}
				return TextStyle(textStyleObject: textStyleObject, colorStyle: colorStyle)
		}
		self.currentStyles = previousStyles ?? []
	}
}
