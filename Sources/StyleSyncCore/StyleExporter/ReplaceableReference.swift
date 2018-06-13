//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

struct ReplaceableReference {
	var fromReference: String
	var toReference: String
}

extension ReplaceableReference {
	static func referenceToIdentifier(from textStyle: TextStyle, fileType: FileType) -> ReplaceableReference {
		let fileExtension = FileExtension(rawValue: fileType)
		return ReplaceableReference(
			fromReference: textStyle.name.codeName(fileExtension, variableType: .textStyleName),
			toReference: textStyle.identifier
		)
	}
	
	static func referenceFromIdentifier(to textStyle: TextStyle, fileType: FileType) -> ReplaceableReference {
		let fileExtension = FileExtension(rawValue: fileType)
		return ReplaceableReference(
			fromReference: textStyle.identifier,
			toReference: textStyle.name.codeName(fileExtension, variableType: .colorStyleName)
		)
	}
	
	static func referenceToIdentifier(from colorStyle: ColorStyle, fileType: FileType) -> ReplaceableReference {
		let fileExtension = FileExtension(rawValue: fileType)
		return ReplaceableReference(
			fromReference: colorStyle.name.codeName(fileExtension, variableType: .colorStyleName),
			toReference: colorStyle.identifier
		)
	}
	
	static func referenceFromIdentifier(to colorStyle: ColorStyle, fileType: FileType) -> ReplaceableReference {
		let fileExtension = FileExtension(rawValue: fileType)
		return ReplaceableReference(
			fromReference: colorStyle.identifier,
			toReference: colorStyle.name.codeName(fileExtension, variableType: .colorStyleName)
		)
	}
}
