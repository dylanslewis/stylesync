//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files

final class StyleExtractor {
	// MARK: - Stored variables
	
	private var generatedRawTextStylesFile: File!
	private var generatedRawColorStylesFile: File!
	private var styleInput: StyleInput
	
	// MARK: - Computed variables
	
	private lazy var previouslyExportedStyles: (text: [TextStyle], color: [ColorStyle], version: Version)? = {
		return getPreviouslyExportedStylesAndVersion()
	}()
	var previouslyExportedTextStyles: [TextStyle]? {
		return previouslyExportedStyles?.text
	}
	var previouslyExportedColorStyles: [ColorStyle]? {
		return previouslyExportedStyles?.color
	}
	var previousStylesVersion: Version? {
		return previouslyExportedStyles?.version
	}
	
	lazy var latestTextStyles: [TextStyle] = {
		switch styleInput {
		case .sketch(let sketchDocument):
			return sketchDocument.layerTextStyles.objects
				.flatMap { textStyleObject -> TextStyle? in
					guard
						let color = textStyleObject.value.textStyle.encodedAttributes.color.color,
						let colorStyle = ColorStyle.colorStyle(for: color, in: latestColorStyles)
					else {
						ErrorManager.log(warning: "\(textStyleObject.name) does not use a color from the shared colour scheme")
						return nil
					}
					return TextStyle(textStyleObject: textStyleObject, colorStyle: colorStyle)
			}
		case .lona(_, let textStyles):
			return textStyles
				.flatMap { lonaTextStyle -> TextStyle? in
					guard
						let colorStyle = latestColorStyles.first(where: { $0.identifier == lonaTextStyle.colorName })
					else {
						ErrorManager.log(warning: "\(lonaTextStyle.name) does not use a color from the shared colour scheme")
						return nil
					}
					return TextStyle(lonaTextStyle: lonaTextStyle, colorStyle: colorStyle)
			}
		}
		
	}()
	lazy var latestColorStyles: [ColorStyle] = {
		switch styleInput {
		case .sketch(let sketchDocument):
			return sketchDocument.layerStyles.objects
				.flatMap({ ColorStyle(colorStyleObject: $0) })
		case .lona(let colors, _):
			return colors.map({ ColorStyle(lonaColor: $0) })
		}
	}()
	
	// MARK: - Initializer
	
	init(
		generatedRawTextStylesFile: File,
		generatedRawColorStylesFile: File,
		styleInput: StyleInput
	) {
		self.generatedRawTextStylesFile = generatedRawTextStylesFile
		self.generatedRawColorStylesFile = generatedRawColorStylesFile
		self.styleInput = styleInput
	}
	
	// MARK: - Helpers
	
	private func getPreviouslyExportedStylesAndVersion() -> (text: [TextStyle], color: [ColorStyle], version: Version)? {
		let versionedTextStyles: VersionedStyle.Text
		let versionedColorStyles: VersionedStyle.Color
		
		do {
			versionedTextStyles = try generatedRawTextStylesFile.readAsDecodedJSON()
			versionedColorStyles = try generatedRawColorStylesFile.readAsDecodedJSON()
		} catch {
			return nil
		}
		
		let previousVersion = getPreviousStylesVersion(
			versionedTextStyle: versionedTextStyles,
			versionedColorStyle: versionedColorStyles
		)
		
		print("🔍  Found previously exported styles at v\(previousVersion.stringRepresentation)")
		return (versionedTextStyles.textStyles, versionedColorStyles.colorStyles, previousVersion)
	}
	
	private func getPreviousStylesVersion(
		versionedTextStyle: VersionedStyle.Text,
		versionedColorStyle: VersionedStyle.Color
	) -> Version {
		let textVersion = versionedTextStyle.version
		let colorVersion = versionedColorStyle.version
		if textVersion != colorVersion {
			ErrorManager.log(
				warning: "Mismatching versions: \(textVersion.stringRepresentation) (Text) and \(colorVersion.stringRepresentation) (Color)"
			)
		}
		return textVersion
	}
}
