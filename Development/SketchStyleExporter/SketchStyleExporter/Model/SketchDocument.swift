//
//  SketchSketchDocument.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

// MARK: - Sketch Document

struct SketchDocument: Codable {
	let layerStyles: ColorStyles
}

// MARK: - Color Styles

extension SketchDocument {
	struct ColorStyles: Codable {
		let objects: [Object]
		
		struct Object: Codable {
			let name: String
			let value: Value
			
			struct Value: Codable {
				let fills: [Fill]
				
				struct Fill: Codable {
					let color: Color

					struct Color: Codable {
						let red: CGFloat
						let green: CGFloat
						let blue: CGFloat
						let alpha: CGFloat
					}
				}
			}
		}
	}
}
