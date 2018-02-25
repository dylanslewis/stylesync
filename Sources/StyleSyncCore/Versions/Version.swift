//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

/// A major and minor version representation.
public struct Version {
	var major: Int
	var minor: Int
	
	public init(major: Int, minor: Int) {
		self.major = major
		self.minor = minor
	}
	
	public init?(versionString: String) {
		let numberFormatter = NumberFormatter()
		let versionComponents = versionString
			.components(separatedBy: ".")
			.flatMap { component in
				return numberFormatter.number(from: component)?.intValue
		}
		guard
			versionComponents.count == 2,
			let major = versionComponents.first,
			let minor = versionComponents.last
		else {
			return nil
		}
		self.init(major: major, minor: minor)
	}
	
	public var stringRepresentation: String {
		return "\(major).\(minor)"
	}
}

extension Version {
	init(
		oldColorStyles: [CodeTemplateReplacableStyle]?,
		oldTextStyles: [CodeTemplateReplacableStyle]?,
		newColorStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle],
		previousStylesVersion: Version?
	) {
		guard
			let previousStylesVersion = previousStylesVersion,
			let oldColorStyles = oldColorStyles,
			let oldTextStyles = oldTextStyles
		else {
			self = .firstVersion
			return
		}

		let didColorStylesChange = oldColorStyles != newColorStyles
		let didTextStylesChange = oldTextStyles != newTextStyles
		let didStylesChange = didColorStylesChange || didTextStylesChange

		let oldColorStyleIdentifiers = oldColorStyles.map { $0.identifier }
		let oldTextStyleIdentifiers = oldTextStyles.map { $0.identifier }
		let newColorStyleIdentifiers = newColorStyles.map { $0.identifier }
		let newTextStyleIdentifiers = newTextStyles.map { $0.identifier }

		var oldColorStyleIdentifiersSet = Set(oldColorStyleIdentifiers)
		var oldTextStyleIdentifiersSet = Set(oldTextStyleIdentifiers)
		let newColorStyleIdentifiersSet = Set(newColorStyleIdentifiers)
		let newTextStyleIdentifiersSet = Set(newTextStyleIdentifiers)
		
		oldColorStyleIdentifiersSet.formIntersection(newColorStyleIdentifiersSet)
		oldTextStyleIdentifiersSet.formIntersection(newTextStyleIdentifiersSet)
		let didRemoveColorStyle = oldColorStyleIdentifiersSet != Set(oldColorStyleIdentifiers)
		let didRemoveTextStyle = oldTextStyleIdentifiersSet != Set(oldTextStyleIdentifiers)
		let didRemoveStyle = didRemoveColorStyle || didRemoveTextStyle
		
		switch (didRemoveStyle, didStylesChange) {
		case (true, _):
			self = previousStylesVersion.incrementingMajor()
		case (false, true):
			self = previousStylesVersion.incrementingMinor()
		case (false, false):
			self = previousStylesVersion
		}
	}
}

extension Version {
	/// Creates a new `Version` by incrementing the `major` and setting the
	/// `minor` to 0.
	///
	/// - Returns: The next major `Version`.
	func incrementingMajor() -> Version {
		var newVersion = self
		newVersion.major = major + 1
		newVersion.minor = 0
		return newVersion
	}

	/// Creates a new `Version` by incrementing the `minor`.
	///
	/// - Returns: The next minor `Version`.
	func incrementingMinor() -> Version {
		var newVersion = self
		newVersion.minor = minor + 1
		return newVersion
	}
}

extension Version {
	/// Version 1.0
	static let firstVersion = Version(versionString: "1.0")!
}

extension Version: Equatable {
	public static func == (lhs: Version, rhs: Version) -> Bool {
		return lhs.major == rhs.major
			&& lhs.minor == rhs.minor
	}
}
