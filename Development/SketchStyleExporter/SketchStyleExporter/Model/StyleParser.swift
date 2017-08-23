//
//  StyleParser.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 23/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

struct StyleParser<S: Style> {
	var newStyles: [S]
	var currentStyles: [S]
	
	var currentAndMigratedStyles: [(currentStyle: S, migratedStyle: S)] {
		return currentStyles
			.flatMap { style -> (S, S)? in
				guard
					let migratedStyle = newStyles.first(where: { $0.identifier == style.identifier && $0.codeName != style.codeName })
					else {
						return nil
				}
				return (style, migratedStyle)
		}
	}
}
