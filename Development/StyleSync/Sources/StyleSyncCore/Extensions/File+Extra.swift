//
//  File+Extra.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 10/09/2017.
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
