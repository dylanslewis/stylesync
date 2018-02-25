//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files

public class SketchManager {
	// MARK: - Stored variables
	
	private var sketchFile: File

	// MARK: - Initializer
	
	public init(sketchFile: File) {
		self.sketchFile = sketchFile
	}
	
	// MARK: - Actions

	public func getSketchDocument() throws -> SketchDocument {
		print("Extracting styles from \(sketchFile.path)")
		
		let zipManager = try ZipManager(zippedFile: sketchFile)
		let sketchDocumentFile = try zipManager.getSketchDocument()
		let sketchDocument: SketchDocument = try sketchDocumentFile.readAsDecodedJSON()
		
		// Remove all the unzipped files.
		try zipManager.cleanup()
		
		return sketchDocument
	}
}
