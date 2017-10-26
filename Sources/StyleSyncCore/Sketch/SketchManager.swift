//
//  SketchManager.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 26/10/2017.
//

import Foundation
import Files

class SketchManager {
	// MARK: - Constants
	
	private enum Constant {
		
	}
	
	// MARK: - Stored variables
	
	private var sketchFile: File
	

	// MARK: - Initializer
	
	init(sketchFile: File) {
		self.sketchFile = sketchFile
	}
	
	// MARK: - Actions

	func getSketchDocument() throws -> SketchDocument {
		print("Extracting styles from \(sketchFile.path)")
		
		let zipManager = try ZipManager(zippedFile: sketchFile)
		let sketchDocumentFile = try zipManager.getSketchDocument()
		let sketchDocument: SketchDocument = try sketchDocumentFile.readAsDecodedJSON()
		
		// Remove all the unzipped files.
		try zipManager.cleanup()
		
		return sketchDocument
	}
}
