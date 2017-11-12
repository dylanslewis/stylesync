//
//  SketchSketchDocument.swift
//  StyleSync
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

// MARK: - Sketch Document

public struct SketchDocument: Codable {
	public let layerStyles: ColorStyles
	public let layerTextStyles: TextStyles
}

// MARK: - Color Styles

public extension SketchDocument {
	public struct ColorStyles: Codable {
		public let objects: [Object]
		
		public struct Object: Codable {
			public let name: String
			public let value: Value
			public let identifier: String
			
			enum CodingKeys: String, CodingKey {
				case name
				case value
				case identifier = "do_objectID"
			}
			
			public struct Value: Codable {
				public let fills: [Fill]
				
				public struct Fill: Codable {
					public let color: Color

					public struct Color: Codable {
						public let red: CGFloat
						public let green: CGFloat
						public let blue: CGFloat
						public let alpha: CGFloat
					}
				}
			}
		}
	}
}

// MARK: - Text Styles

public extension SketchDocument {
	public struct TextStyles: Codable {
		public let objects: [Object]
		
		public struct Object: Codable {
			public let name: String
			public let value: Value
			public let identifier: String
			
			enum CodingKeys: String, CodingKey {
				case name
				case value
				case identifier = "do_objectID"
			}
			
			public struct Value: Codable {
				public let textStyle: TextStyle
				
				public struct TextStyle: Codable {
					public let encodedAttributes: EncodedAttributes

					public struct EncodedAttributes: Codable {
						public let font: Font
						public let color: Color
						public let paragraphStyle: ParagraphStyle
						public let kerning: CGFloat?
						
						public struct Font: Codable {
							let sixtyFourBitRepresentation: String
							public var fontName: String? {
								return fontDescriptor?.fontAttributes[NSFontDescriptor.AttributeName.name] as? String
							}
							public var pointSize: CGFloat? {
								return fontDescriptor?.pointSize
							}
							private var fontDescriptor: NSFontDescriptor? {
								return sixtyFourBitRepresentation.unarchivedObject()
							}
							
							enum CodingKeys: String, CodingKey {
								case sixtyFourBitRepresentation = "_archive"
							}
						}
						
						public struct Color: Codable {
							let sixtyFourBitRepresentation: String
							public var color: NSColor? {
								return sixtyFourBitRepresentation.unarchivedObject()
							}
							
							enum CodingKeys: String, CodingKey {
								case sixtyFourBitRepresentation = "_archive"
							}
						}
						
						public struct ParagraphStyle: Codable {
							let sixtyFourBitRepresentation: String
							public var paragraphStyle: NSParagraphStyle? {
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
