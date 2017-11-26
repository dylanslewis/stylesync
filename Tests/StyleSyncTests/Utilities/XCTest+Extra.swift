//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest

func XCTFailAndAbort(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
	XCTFail(message, file: file, line: line)
	exit(1)
}
