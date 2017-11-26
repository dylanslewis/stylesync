//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Cocoa

extension NSColor {
	typealias Components = (red: Int, green: Int, blue: Int, alpha: CGFloat)
	
	var components: Components {
		return (
			roundedInteger(forComponent: redComponent),
			roundedInteger(forComponent: greenComponent),
			roundedInteger(forComponent: blueComponent),
			alphaComponent
		)
	}
	
	private func roundedInteger(forComponent component: CGFloat) -> Int {
		return Int((component * 255).rounded())
	}
	
	var hex: String {
		return String(format: "%02X%02X%02X", components.red, components.green, components.blue)
	}
}
