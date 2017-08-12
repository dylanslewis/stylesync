//
//  SketchSketchDocument.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

// MARK: - Sketch Document

struct SketchDocument: Codable {
	let layerStyles: ColorStyles
	let layerTextStyles: TextStyles
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

// MARK: - Text Styles

extension SketchDocument {
	struct TextStyles: Codable {
		let objects: [Object]
		
		struct Object: Codable {
			let name: String
			let value: Value
			
			struct Value: Codable {
				let textStyle: TextStyle
				
				struct TextStyle: Codable {
					let encodedAttributes: EncodedAttributes
					
					struct EncodedAttributes: Codable {
						let font: Font
						let color: Color
						let paragraphStyle: ParagraphStyle
						let kerning: CGFloat
						
						struct Font: Codable {
							let sixtyFourBitRepresentation: String
							var fontName: String? {
								return fontDescriptor?.fontAttributes[NSFontDescriptor.AttributeName.name] as? String
							}
							var pointSize: CGFloat? {
								return fontDescriptor?.pointSize
							}
							private var fontDescriptor: NSFontDescriptor? {
								return sixtyFourBitRepresentation.unarchivedObject()
							}
							
							enum CodingKeys: String, CodingKey {
								case sixtyFourBitRepresentation = "_archive"
							}
						}
						
						struct Color: Codable {
							let sixtyFourBitRepresentation: String
							var color: NSColor? {
								return sixtyFourBitRepresentation.unarchivedObject()
							}
							
							enum CodingKeys: String, CodingKey {
								case sixtyFourBitRepresentation = "_archive"
							}
						}
						
						struct ParagraphStyle: Codable {
							let sixtyFourBitRepresentation: String
							var paragraphStyle: NSParagraphStyle? {
								return sixtyFourBitRepresentation.unarchivedObject()
							}
							
							enum CodingKeys: String, CodingKey {
								case sixtyFourBitRepresentation = "_archive"
							}
						}
						
						enum CodingKeys: String, CodingKey {
							case font = "MSAttributedStringFontAttribute"
							case color = "NSColor"
							case kerning = "NSKern"
							case paragraphStyle = "NSParagraphStyle"
						}
					}
				}
			}
		}
	}
}
