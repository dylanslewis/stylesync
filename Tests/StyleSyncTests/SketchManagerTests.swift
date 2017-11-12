//
//  SketchManagerTests.swift
//  StyleSyncTests
//
//  Created by Dylan Lewis on 11/11/2017.
//

import XCTest
import StyleSyncCore
import Files

class SketchManagerTests: XCTestCase {	
	func testSketchFileWithSharedTextStylesAndNoSharedLayerStylesHasNoColorStyles() throws {
		let sketchDocument = try self.sketchDocument(withName: "SketchFileWithOneTextStyleAndNoColorStyles")
		XCTAssertEqual(sketchDocument.layerStyles.objects.count, 0)
	}

	//	func testSketchFileWithNoSharedTextStylesHasNoTextStyles() throws {
	//
	//	}
	//
	//	func testSketchManagerCleanupRemovesAllUnusedFiles() {
	//
	//	}
	
	// MARK: - Helpers
	
	private func sketchDocument(withName name: String) throws -> SketchDocument {
		let sketchFile = try testResources.file(named: "\(name).sketch")
		let sketchManager = SketchManager(sketchFile: sketchFile)
		return try sketchManager.getSketchDocument()
	}
}
