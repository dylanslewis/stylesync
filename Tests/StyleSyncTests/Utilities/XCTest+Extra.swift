//
//  XCTest+Extra.swift
//  StyleSyncTests
//
//  Created by Dylan Lewis on 12/11/2017.
//

import XCTest

func XCTFailAndAbort(_ message: String, file: StaticString = #file, line: UInt = #line) -> Never {
	XCTFail(message, file: file, line: line)
	exit(1)
}
