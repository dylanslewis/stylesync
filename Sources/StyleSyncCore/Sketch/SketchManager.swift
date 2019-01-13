//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files

public class SketchManager {
	// MARK: - Constants
	
	private enum Constant {
		static let minimumVersion = Version(major: 50, minor: 0)
	}
	
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
		
		defer {
			// Remove all the unzipped files.
			do {
				try zipManager.cleanup()
			} catch {
				ErrorManager.log(error: error, context: .sketch)
			}
		}
		
		let sketchMetadataFile = try zipManager.getSketchMetadata()
		let sketchMetadata: SketchMetadata = try sketchMetadataFile.readAsDecodedJSON()
		print("Decoded Sketch metadata")
		
		guard sketchMetadata.appVersion >= Constant.minimumVersion else {
			throw Error.unsupportedVersion
		}
		
		let sketchDocumentFile = try zipManager.getSketchDocument()
		let sketchDocument: SketchDocument = try sketchDocumentFile.readAsDecodedJSON()
		print("Decoded Sketch document")
		
		return sketchDocument
	}
}

extension SketchManager {
	public enum Error: Swift.Error, CustomStringConvertible {
		case unsupportedVersion
		
		public var description: String {
			switch self {
			case .unsupportedVersion:
				return "stylesync supports a minimum Sketch version of 50. If you have Sketch v50, simply open your document and save to update it. If you don't, you can download a supported version from: \(GitHubLink.lastSupportedVersionBefore50)"
			}
		}
	}
}
