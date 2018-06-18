//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Cocoa

struct TextStyle: Style, Codable {
	let name: String
	let identifier: String
	let groupedIdentifiers: [String]?
	let fontName: String
	let pointSize: CGFloat
	let kerning: CGFloat
	let lineHeight: CGFloat
	let colorStyle: ColorStyle?
	let isDeprecated: Bool
	
	init(
		name: String,
		identifier: String,
		groupedIdentifiers: [String]?,
		fontName: String,
		pointSize: CGFloat,
		kerning: CGFloat,
		lineHeight: CGFloat,
		colorStyle: ColorStyle?,
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
		self.groupedIdentifiers = groupedIdentifiers
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
			groupedIdentifiers: nil,
			fontName: font.fontName,
			pointSize: font.pointSize,
			kerning: textAttributes.kerning ?? 0,
			lineHeight: lineHeight,
			colorStyle: colorStyle,
			isDeprecated: isDeprecated
		)
	}
	
	init?(name: String, textStyleObjects: [SketchDocument.TextStyles.Object], isDeprecated: Bool = false) {
		guard
			let fontName = textStyleObjects.fontName(forStyleName: name),
			let pointSize = textStyleObjects.pointSize(forStyleName: name),
			let lineHeight = textStyleObjects.lineHeight(forStyleName: name)
		else {
			ErrorManager.log(warning: "Failed to find valid text attributes for \(name)")
			return nil
		}
		
		let identifier = textStyleObjects.reduce("", { $0 + $1.identifier })
		let groupedIdentifiers = textStyleObjects.map({ $0.identifier })
		let kerning = textStyleObjects.kerning(forStyleName: name)
		
		self.init(
			name: name,
			identifier: identifier,
			groupedIdentifiers: groupedIdentifiers,
			fontName: fontName,
			pointSize: pointSize,
			kerning:  kerning ?? 0,
			lineHeight: lineHeight,
			colorStyle: nil,
			isDeprecated: isDeprecated
		)
	}
}

private extension Array where Element == SketchDocument.TextStyles.Object {
	func fontName(forStyleName styleName: String) -> String? {
		return self
			.map({ $0.value.textStyle.encodedAttributes })
			.map({ $0.font.fontName })
			.reduce(nil, { currentFontName, fontName in
				if let currentFontName = currentFontName, currentFontName != fontName {
					ErrorManager.log(warning: "\(styleName) has an inconsistent font name (\(currentFontName)) and \(fontName))")
				}
				return fontName
			})
	}
	
	func pointSize(forStyleName styleName: String) -> CGFloat? {
		return self
			.map({ $0.value.textStyle.encodedAttributes })
			.map({ $0.font.pointSize })
			.reduce(nil, { currentPointSize, pointSize in
				if let currentPointSize = currentPointSize, currentPointSize != pointSize {
					ErrorManager.log(warning: "\(styleName) has an inconsistent point size (\(currentPointSize) and \(pointSize))")
				}
				return pointSize
			})
	}
	
	func lineHeight(forStyleName styleName: String) -> CGFloat? {
		return self
			.map({ $0.value.textStyle.encodedAttributes })
			.map({ $0.paragraphStyle.maximumLineHeight })
			.reduce(nil, { currentLineHeight, lineHeight in
				if let currentLineHeight = currentLineHeight, currentLineHeight != lineHeight {
					let lineHeightString: String
					if let lineHeight = lineHeight {
						lineHeightString = "\(lineHeight)"
					} else {
						lineHeightString = "nil"
					}
					ErrorManager.log(warning: "\(styleName) has an inconsistent line height value (\(currentLineHeight) and \(lineHeightString))")
				}
				return lineHeight
			})
	}
	
	func kerning(forStyleName styleName: String) -> CGFloat? {
		return self
			.map({ $0.value.textStyle.encodedAttributes })
			.map({ $0.kerning })
			.reduce(nil, { currentKerning, kerning in
				if let currentKerning = currentKerning, currentKerning != kerning {
					let kerningString: String
					if let kerning = kerning {
						kerningString = "\(kerning)"
					} else {
						kerningString = "nil"
					}
					ErrorManager.log(warning: "\(styleName) has an inconsistent kerning value (\(currentKerning) and \(kerningString))")
				}
				return kerning
			})
	}
}

extension TextStyle {
	// FIXME: Support styles migrated from/to non-namespaced styles
	func isTheSameStyle(as style: Style) -> Bool {
		if
			let groupedIdentifiers = self.groupedIdentifiers,
			let oldPreviousIdentifiers = (style as? TextStyle)?.groupedIdentifiers
		{
			let groupedIdentifiersSet = Set(groupedIdentifiers)
			let oldPreviousIdentifiersSet = Set(oldPreviousIdentifiers)
			
			// At least one identifier remains constant.
			return groupedIdentifiersSet.intersection(oldPreviousIdentifiersSet).isEmpty == false
		} else {
			return identifier == style.identifier
		}
	}
}

// MARK: - Equatable

extension TextStyle: Equatable {
	static func == (lhs: TextStyle, rhs: TextStyle) -> Bool {
		return
			lhs.name == rhs.name &&
			lhs.identifier == rhs.identifier &&
			lhs.groupedIdentifiers == rhs.groupedIdentifiers &&
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
		let originalHashValue = colorStyle?.hashValue ?? 0
		return
			originalHashValue ^
			name.hashValue ^
			identifier.hashValue ^
			(groupedIdentifiers ?? []).reduce(0, { $0.hashValue ^ $1.hashValue }) ^
			fontName.hashValue ^
			pointSize.hashValue ^
			kerning.hashValue ^
			lineHeight.hashValue ^
			isDeprecated.hashValue
	}
}

// MARK: - Deprecatable

extension TextStyle {
	var deprecated: Style {
		return TextStyle(
			name: name,
			identifier: identifier,
			groupedIdentifiers: groupedIdentifiers,
			fontName: fontName,
			pointSize: pointSize,
			kerning: kerning,
			lineHeight: lineHeight,
			colorStyle: colorStyle,
			isDeprecated: true
		)
	}
}
