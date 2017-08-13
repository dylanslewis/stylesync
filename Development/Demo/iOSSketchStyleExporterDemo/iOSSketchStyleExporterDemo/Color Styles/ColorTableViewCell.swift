//
//  ColorTableViewCell.swift
//  iOSSketchStyleExporterDemo
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import UIKit

class ColorTableViewCell: UITableViewCell {
	@IBOutlet private var colorView: UIView! {
		didSet {
			colorView.layer.cornerRadius = 2
		}
	}
	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var codeNameLabel: UILabel!
	@IBOutlet private var hexLabel: UILabel!
	@IBOutlet private var rgbLabel: UILabel!
	
	func configure(with viewData: ViewData, textStyle: TextStyle) {
		colorView.backgroundColor = viewData.color
		nameLabel.attributedText = NSAttributedString(string: viewData.name, textStyle: textStyle)
		codeNameLabel.attributedText = NSAttributedString(string: viewData.codeName, textStyle: .monospaced)
		hexLabel.attributedText = NSAttributedString(string: "#\(viewData.hex)", textStyle: .monospaced)
		rgbLabel.attributedText = NSAttributedString(string: "\(viewData.red), \(viewData.green), \(viewData.blue), \(viewData.alpha)", textStyle: .monospaced)
	}
}

extension TextStyle {
	static let monospaced = TextStyle(
		fontName: "CourierNewPS-BoldMT",
		pointSize: 12,
		color: .gray,
		kerning: 0,
		lineHeight: 0
	)
}

extension NSAttributedString {
	convenience init(withMonospacedString string: String) {
		let attributes: [NSAttributedStringKey: Any] = [
			.font: UIFont.monospacedDigitSystemFont(ofSize: TextStyle.sampleBody.font.pointSize, weight: .light),
			.foregroundColor: TextStyle.sampleBody.color,
		]
		self.init(string: string, attributes: attributes)
	}
}

extension ColorTableViewCell {
	struct ViewData {
		let name: String
		let codeName: String
		let color: UIColor
		let hex: String
		let red: String
		let green: String
		let blue: String
		let alpha: String
		
		init?(name: String, codeName: String, color: UIColor) {
			guard let components = color.components else { return nil }
			self.name = name
			self.codeName = codeName
			self.color = color
			self.hex = color.hex ?? "123456"
			self.red = String(describing: components.red)
			self.green = String(describing: components.green)
			self.blue = String(describing: components.blue)
			self.alpha = String(describing: components.alpha)
		}
	}
}

extension UIColor {
	var components: (red: Int, green: Int, blue: Int, alpha: CGFloat)? {
		var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		return getRed(&r, green: &g, blue: &b, alpha: &a) ? (Int((r*255).rounded()), Int((g*255).rounded()), Int((b*255).rounded()), a) : nil
	}
	
	var hex: String? {
		guard let components = components else { return nil }
		return String(format: "%02X%02X%02X", components.red, components.green, components.blue)
	}
}
