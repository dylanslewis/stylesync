//
//  SketchMetadata.swift
//  StyleSync
//
//  Created by Dylan Lewis on 12/05/2018.
//

import Foundation

public struct SketchMetadata: Codable {
	public let appVersion: Version
	
	// MARK: - Codable
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let versionString = try values.decode(String.self, forKey: .appVersionString)
		guard let version = Version(versionString: versionString) else {
			throw Error.failedToCreateVersion(versionString: versionString)
		}
		self.appVersion = version
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(appVersion.stringRepresentation, forKey: .appVersionString)
	}
	
	enum CodingKeys: String, CodingKey {
		case appVersionString = "appVersion"
	}
}

// MARK: - Error

extension SketchMetadata {
	enum Error: Swift.Error, CustomStringConvertible {
		case failedToCreateVersion(versionString: String)
		
		var description: String {
			switch self {
			case .failedToCreateVersion(let versionString):
				return "Failed to create Version from \(versionString)"
			}
		}
	}
}

