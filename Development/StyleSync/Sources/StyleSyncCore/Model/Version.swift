//
//  Version.swift
//  StyleSync
//
//  Created by Dylan Lewis on 19/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

/// A major and minor version representation.
struct Version {
	var major: Int
	var minor: Int
	
	init?(versionString: String) {
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
		self.major = major
		self.minor = minor
	}
	
	var stringRepresentation: String {
		return "\(major).\(minor)"
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
