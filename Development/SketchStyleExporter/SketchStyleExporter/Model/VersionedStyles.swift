//
//  VersionedStyles.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 19/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

/// A structure representing the version of the style sheet and all the color
/// and text styles.
struct VersionedStyles {
	let version: Version
	let colorStyles: [ColorStyle]
	let textStyles: [TextStyle]
}

// MARK: - Codable

extension VersionedStyles: Codable {
	enum CodingKeys: String, CodingKey {
		case version, colorStyles, textStyles
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let versionString = try container.decode(String.self, forKey: .version)
		
		guard let version = Version(versionString: versionString) else {
			throw CodableError.cannotDecode
		}
		self.version = version
		self.colorStyles = try container.decode([ColorStyle].self, forKey: .colorStyles)
		self.textStyles = try container.decode([TextStyle].self, forKey: .textStyles)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(version.stringRepresentation, forKey: .version)
		try container.encode(colorStyles, forKey: .colorStyles)
		try container.encode(textStyles, forKey: .textStyles)
	}
}
