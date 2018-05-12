//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Cocoa

struct TextStyle: Style, Codable {
	let name: String
	let identifier: String
	let fontName: String
	let pointSize: CGFloat
	let kerning: CGFloat
	let lineHeight: CGFloat
	let colorStyle: ColorStyle
	let isDeprecated: Bool
	
	init(
		name: String,
		identifier: String,
		fontName: String,
		pointSize: CGFloat,
		kerning: CGFloat,
		lineHeight: CGFloat,
		colorStyle: ColorStyle,
		isDeprecated: Bool
	) {
		let nonZeroLineHeight: CGFloat
		if lineHeight == 0, let defaultLineHeight = NSFont.defaultLineHeight(fontName: fontName, pointSize: pointSize) {
			nonZeroLineHeight = defaultLineHeight
		} else {
			nonZeroLineHeight = lineHeight
		}
		
		self.name = name
		self.identifier = identifier
		self.fontName = fontName
		self.pointSize = pointSize.roundedToTwoDecimalPlaces
		self.kerning = kerning.roundedToTwoDecimalPlaces
		self.lineHeight = nonZeroLineHeight.roundedToTwoDecimalPlaces
		self.colorStyle = colorStyle
		self.isDeprecated = isDeprecated
	}
	
	init?(textStyleObject: SketchDocument.TextStyles.Object, colorStyle: ColorStyle, isDeprecated: Bool = false) {
		let textAttributes = textStyleObject.value.textStyle.encodedAttributes
		guard let lineHeight = textAttributes.paragraphStyle.maximumLineHeight else {
			ErrorManager.log(warning: "Failed to parse text style with name \(textStyleObject.name)\n\n\(textStyleObject)", isBug: true)
			return nil
		}
		let font = textAttributes.font
	
		self.init(
			name: textStyleObject.name,
			identifier: textStyleObject.identifier,
			fontName: font.fontName,
			pointSize: font.pointSize,
			kerning: textAttributes.kerning ?? 0,
			lineHeight: lineHeight,
			colorStyle: colorStyle,
			isDeprecated: isDeprecated
		)
	}
}

// MARK: - Equatable

extension TextStyle: Equatable {
	static func == (lhs: TextStyle, rhs: TextStyle) -> Bool {
		return
			lhs.name == rhs.name &&
			lhs.identifier == rhs.identifier &&
			lhs.fontName == rhs.fontName &&
			lhs.pointSize == rhs.pointSize &&
			lhs.kerning == rhs.kerning &&
			lhs.lineHeight == rhs.lineHeight &&
			lhs.colorStyle == rhs.colorStyle &&
			lhs.isDeprecated == rhs.isDeprecated
	}
}

// MARK: - Hashable

extension TextStyle: Hashable {
	var hashValue: Int {
		return
			name.hashValue ^
			identifier.hashValue ^
			fontName.hashValue ^
			pointSize.hashValue ^
			kerning.hashValue ^
			lineHeight.hashValue ^
			colorStyle.hashValue ^
			isDeprecated.hashValue
	}
}

// MARK: - Deprecatable

extension TextStyle {
	var deprecated: Style {
		return TextStyle(
			name: name,
			identifier: identifier,
			fontName: fontName,
			pointSize: pointSize,
			kerning: kerning,
			lineHeight: lineHeight,
			colorStyle: colorStyle,
			isDeprecated: true
		)
	}
}
