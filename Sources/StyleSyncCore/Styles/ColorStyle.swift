//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Cocoa

struct ColorStyle: Style {
	let name: String
	let identifier: String
	let color: NSColor
	var isDeprecated: Bool
	
	init(name: String, identifier: String, color: NSColor, isDeprecated: Bool) {
		self.name = name
		self.identifier = identifier
		self.color = color
		self.isDeprecated = isDeprecated
	}
	
	init?(colorStyleObject: SketchDocument.ColorStyles.Object, isDeprecated: Bool = false) {
		guard let colorFill = colorStyleObject.value.fills.first else {
			ErrorManager.log(warning: "Failed to parse color style with name \(colorStyleObject.name)\n\n\(colorStyleObject)", isBug: true)
			return nil
		}
		let red = colorFill.color.red
		let green = colorFill.color.green
		let blue = colorFill.color.blue
		let alpha = colorFill.color.alpha
		
		self.name = colorStyleObject.name
		self.identifier = colorStyleObject.identifier
		self.color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
		self.isDeprecated = isDeprecated
	}
}

// MARK: - Codable

extension ColorStyle: Codable {
	enum CodingKeys: String, CodingKey {
		case name, identifier, red, green, blue, alpha, isDeprecated
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let red = try container.decode(CGFloat.self, forKey: .red)
		let green = try container.decode(CGFloat.self, forKey: .green)
		let blue = try container.decode(CGFloat.self, forKey: .blue)
		let alpha = try container.decode(CGFloat.self, forKey: .alpha)
		
		self.name = try container.decode(String.self, forKey: .name)
		self.identifier = try container.decode(String.self, forKey: .identifier)
		self.color = NSColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
		self.isDeprecated = try container.decode(Bool.self, forKey: .isDeprecated)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(identifier, forKey: .identifier)
		try container.encode(color.redComponent*255, forKey: .red)
		try container.encode(color.greenComponent*255, forKey: .green)
		try container.encode(color.blueComponent*255, forKey: .blue)
		try container.encode(color.alphaComponent, forKey: .alpha)
		try container.encode(isDeprecated, forKey: .isDeprecated)
	}
}

// MARK: - Equatable

extension ColorStyle: Equatable {
	static func == (lhs: ColorStyle, rhs: ColorStyle) -> Bool {
		return
			lhs.name == rhs.name &&
			lhs.identifier == rhs.identifier &&
			lhs.color == rhs.color &&
			lhs.isDeprecated == rhs.isDeprecated
	}
}

// MARK: - Hashable

extension ColorStyle: Hashable {
	var hashValue: Int {
		return
			name.hashValue ^
			identifier.hashValue ^
			color.hashValue ^
			isDeprecated.hashValue
	}
}

// MARK: - Deprecatable

extension ColorStyle {
	var deprecated: Style {
		return ColorStyle(
			name: name,
			identifier: identifier,
			color: color,
			isDeprecated: true
		)
	}
}

// MARK: - Helpers

extension ColorStyle {
	static func colorStyle(for color: NSColor, in colorStyles: [ColorStyle]) -> ColorStyle? {
		return colorStyles.first(where: { $0.color.components == color.components })
	}
}
