//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import AppKit

struct Lona: Codable {
	var colors: [Color]?
	var textStyles: [Text]?
	
	enum CodingKeys: String, CodingKey {
		case colors
		case textStyles = "styles"
	}
	
	struct Color: Codable {
		let identifier: String
		let name: String
		let hexValue: String
		let comment: String?
		var color: NSColor {
			return NSColor(hexString: hexValue)
		}
		
		enum CodingKeys: String, CodingKey {
			case identifier = "id"
			case name
			case hexValue = "value"
			case comment
		}
	}

	struct Text: Codable {
		let identifier: String
		let name: String
		let fontFamily: String
		let fontWeight: String // TODO: Might be a String in the spec?
		let fontSize: CGFloat
		let lineHeight: CGFloat
		let letterSpacing: CGFloat
		// TODO: Support non-shared colours
		let colorName: String
		
		enum CodingKeys: String, CodingKey {
			case identifier = "id"
			case name
			case fontFamily
			case fontWeight
			case fontSize
			case lineHeight
			case letterSpacing
			case colorName = "color"
		}
	}
}
