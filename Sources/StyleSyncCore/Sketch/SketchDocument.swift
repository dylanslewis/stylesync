//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
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
						public let color: NSColor
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
						
						public struct PreVersion48Color: Codable {
							let sixtyFourBitRepresentation: String
							public var color: NSColor? {
								return sixtyFourBitRepresentation.unarchivedObject()
							}
							
							enum CodingKeys: String, CodingKey {
								case sixtyFourBitRepresentation = "_archive"
							}
						}
						
						public struct PostVersion48Color: Codable {
							let red: CGFloat
							let green: CGFloat
							let blue: CGFloat
							let alpha: CGFloat
							public var color: NSColor {
								return NSColor(red: red, green: green, blue: blue, alpha: alpha)
							}
							
							public init(color: NSColor) {
								self.red = color.redComponent
								self.green = color.greenComponent
								self.blue = color.blueComponent
								self.alpha = color.alphaComponent
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
						
						public init(from decoder: Decoder) throws {
							let values = try decoder.container(keyedBy: CodingKeys.self)
							do {
								// First try to decode using the old
								// standard.
								let rawRepresentation = try values.decode(PreVersion48Color.self, forKey: .preVersion48Color)
								guard let color = rawRepresentation.color else {
									throw Error.failedToParseColor
								}
								self.color = color
							} catch {
								let explicitRepresentation = try values.decode(PostVersion48Color.self, forKey: .postVersion48Color)
								self.color = explicitRepresentation.color
							}
							self.font = try values.decode(Font.self, forKey: .font)
							self.paragraphStyle = try values.decode(ParagraphStyle.self, forKey: .paragraphStyle)
							do {
								self.kerning = try values.decode(CGFloat.self, forKey: .kerning)
							} catch {
								self.kerning = nil
							}
						}
						
						public init(font: Font, color: NSColor, paragraphStyle: ParagraphStyle, kerning: CGFloat?) {
							self.font = font
							self.color = color
							self.paragraphStyle = paragraphStyle
							self.kerning = kerning
						}
						
						public func encode(to encoder: Encoder) throws {
							var container = encoder.container(keyedBy: CodingKeys.self)
							let postVersion48Color = PostVersion48Color(color: color)
							try container.encode(postVersion48Color, forKey: .postVersion48Color)
							try container.encode(font, forKey: .font)
							try container.encode(paragraphStyle, forKey: .paragraphStyle)
							try container.encode(kerning, forKey: .kerning)
						}
						
						enum CodingKeys: String, CodingKey {
							case font = "MSAttributedStringFontAttribute"
							case preVersion48Color = "NSColor"
							case postVersion48Color = "MSAttributedStringColorDictionaryAttribute"
							case kerning = "NSKern"
							case paragraphStyle = "NSParagraphStyle"
						}
						
						enum Error: Swift.Error {
							case failedToParseColor
						}
					}
				}
			}
		}
	}
}
