//
//  UIColor+Extra.swift
//  StyleGuide
//
//  Created by Dylan Lewis on 14/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import UIKit

extension UIColor {
	var components: (red: Int, green: Int, blue: Int, alpha: CGFloat)? {
		var red: CGFloat = 0
		var green: CGFloat = 0
		var blue: CGFloat = 0
		var alpha: CGFloat = 0
		guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) == true else {
			return nil
		}
		return (
			roundedInteger(forComponent: red),
			roundedInteger(forComponent: green),
			roundedInteger(forComponent: blue),
			alpha
		)
	}
	
	private func roundedInteger(forComponent component: CGFloat) -> Int {
		return Int((component * 255).rounded())
	}
	
	var hex: String? {
		guard let components = components else { return nil }
		return String(format: "%02X%02X%02X", components.red, components.green, components.blue)
	}
}
