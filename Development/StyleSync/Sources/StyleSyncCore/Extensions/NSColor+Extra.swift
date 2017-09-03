//
//  NSColor+Extra.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Cocoa

extension NSColor {
	var components: (red: Int, green: Int, blue: Int, alpha: CGFloat) {
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
