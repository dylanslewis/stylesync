//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import AppKit

extension NSFont {
	/// Gets the default line height of a font with a given font name and
	///	point size.
	///
	/// - Parameters:
	///   - fontName: The font's name.
	///   - pointSize: The font's point size.
	/// - Returns: The default line height, or `nil` if the font name is
	///		invalid.
	static func defaultLineHeight(fontName: String, pointSize: CGFloat) -> CGFloat? {
		guard let font = NSFont(name: fontName, size: pointSize) else {
			return nil
		}
		let layoutManager = NSLayoutManager()
		return layoutManager.defaultLineHeight(for: font)
	}
}
