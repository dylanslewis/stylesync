//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

public typealias FileType = String

extension FileType {
	static let json: FileType = "json"
	static let log: FileType = "log"
	static let markdown: FileType = "md"
	static let xcodeProject: FileType = "xcodeproj"
	static let xcodeScheme: FileType = "xcscheme"
}
