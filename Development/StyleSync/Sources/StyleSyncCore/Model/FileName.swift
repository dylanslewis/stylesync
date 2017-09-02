//
//  FileName.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 02/09/2017.
//

import Foundation

/// Describes a file name and type.
struct FileName {
	let name: String
	let type: FileType
}

extension FileName {
	typealias FileType = String
}

extension FileName.FileType {
	static let json: FileName.FileType = "json"
}

extension FileName {
	var stringRepresentation: String {
		return name + "." + type
	}
}

extension URL {
	func appending(fileName: FileName) -> URL {
		return appendingPathComponent(fileName.stringRepresentation)
	}
}
