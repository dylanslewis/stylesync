//
//  FileManager+Extra.swift
//  StyleSync
//
//  Created by Dylan Lewis on 02/09/2017.
//

import Foundation

public typealias FileOperation = (URL, String) -> Void

extension FileManager {
	enum Error: Swift.Error {
		case unableToEnumerateFiles
	}
		
	func iterateOverFiles(
		inDirectory directory: URL,
		fileTypes: Set<FileName.FileType>,
		ignoredFileURLs: [URL],
		fileOperations: [FileOperation]
	) throws {
		guard let enumerator = enumerator(at: directory, includingPropertiesForKeys: nil) else {
			throw Error.unableToEnumerateFiles
		}
		while let element = enumerator.nextObject() as? String {
			let fullPath = directory.appendingPathComponent(element)
			guard
				fileTypes.first(where: { element.hasSuffix($0) }) != nil,
				!ignoredFileURLs.contains(fullPath)
			else {
				continue
			}
			
			guard let fileContents = stringContents(at: fullPath) else {
				print("⚠️ Unable to open file at: \(fullPath)")
				continue
			}
			
			// Perform each of the operations.
			fileOperations.forEach({ $0(fullPath, fileContents) })
		}
	}
	
	func contents(at url: URL) -> Data? {
		return contents(atPath: url.absoluteString)
	}
	
	func stringContents(at url: URL, encoding: String.Encoding = .utf8) -> String? {
		guard let fileData = contents(at: url) else {
			return nil
		}
		return String(data: fileData, encoding: encoding)
	}
}
