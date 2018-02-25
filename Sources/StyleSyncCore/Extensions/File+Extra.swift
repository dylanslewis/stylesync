//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files

public typealias FileOperation = (File) -> Void

extension File {
	func readAsDecodedJSON<D: Decodable>(usingDecoder decoder: JSONDecoder = .init()) throws -> D {
		let fileData = try read()
		return try decoder.decode(D.self, from: fileData)
	}
}

// MARK: - File + Template

extension File {
	func validateAsTemplateFile() throws {
		if !name.contains("-template.txt") {
			throw TemplateFileError.invalidFileName
		}
	}
}

enum TemplateFileError: Error {
	case invalidFileName
}

// MARK: - Hashable

extension File: Hashable {
	public var hashValue: Int {
		return path.hashValue
	}
}
