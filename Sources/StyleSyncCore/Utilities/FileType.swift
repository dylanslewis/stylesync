//
//  FileType.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 02/09/2017.
//

import Foundation

public typealias FileType = String

extension FileType {
	static let json: FileType = "json"
	static let xcodeProject: FileType = "xcodeproj"
	static let xcodeScheme: FileType = "xcscheme"
}
