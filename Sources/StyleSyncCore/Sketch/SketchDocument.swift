//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Cocoa

// MARK: - Sketch Document

protocol ABCColorStyle {
	var name: String { get }
	var identifier: String { get }
	var color: NSColor { get }
}

public struct SketchDocument: Codable {
	public let assets: ColorAssets
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

public extension SketchDocument {
	public struct ColorAssets: Codable {
		public struct ColorAsset {
			public let name: String
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
							public let attributes: Attributes
							public var fontName: String {
								return attributes.fontName
							}
							public var pointSize: CGFloat {
								return attributes.pointSize
							}
							
							public struct Attributes: Codable {
								public let fontName: String
								public let pointSize: CGFloat
								
								enum CodingKeys: String, CodingKey {
									case fontName = "name"
									case pointSize = "size"
								}
							}
						}
						
						public struct Color: Codable {
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
							public var textAlignment: NSTextAlignment
							public var minimumLineHeight: CGFloat?
							public var maximumLineHeight: CGFloat?
							
							public init(
								textAlignment: NSTextAlignment,
								minimumLineHeight: CGFloat?,
								maximumLineHeight: CGFloat?
							) {
								self.textAlignment = textAlignment
								self.minimumLineHeight = minimumLineHeight
								self.maximumLineHeight = maximumLineHeight
							}
							
							public init(from decoder: Decoder) throws {
								let values = try decoder.container(keyedBy: CodingKeys.self)
								self.textAlignment = try values.decode(NSTextAlignment.self, forKey: .textAlignment)
								self.minimumLineHeight = try? values.decode(CGFloat.self, forKey: .minimumLineHeight)
								self.maximumLineHeight = try? values.decode(CGFloat.self, forKey: .maximumLineHeight)
							}
							
							enum CodingKeys: String, CodingKey {
								case textAlignment = "alignment"
								case minimumLineHeight = "minimumLineHeight"
								case maximumLineHeight = "maximumLineHeight"
							}
						}
						
						public init(font: Font, color: NSColor, paragraphStyle: ParagraphStyle, kerning: CGFloat?) {
							self.font = font
							self.color = color
							self.paragraphStyle = paragraphStyle
							self.kerning = kerning
						}
						
						public init(from decoder: Decoder) throws {
							let values = try decoder.container(keyedBy: CodingKeys.self)
							self.color = try values.decode(Color.self, forKey: .color).color
							self.font = try values.decode(Font.self, forKey: .font)
							self.paragraphStyle = try values.decode(ParagraphStyle.self, forKey: .paragraphStyle)
							self.kerning = try? values.decode(CGFloat.self, forKey: .kerning)
						}
						
						public func encode(to encoder: Encoder) throws {
							var container = encoder.container(keyedBy: CodingKeys.self)
							let color = Color(color: self.color)
							try container.encode(color, forKey: .color)
							try container.encode(font, forKey: .font)
							try container.encode(paragraphStyle, forKey: .paragraphStyle)
							try container.encode(kerning, forKey: .kerning)
						}
						
						enum CodingKeys: String, CodingKey {
							case font = "MSAttributedStringFontAttribute"
							case color = "MSAttributedStringColorAttribute"
							case kerning = "kerning"
							case paragraphStyle = "paragraphStyle"
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

extension NSTextAlignment: Codable {}
