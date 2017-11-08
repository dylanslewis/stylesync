//
//  StyleExtractor.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 26/10/2017.
//

import Foundation
import Files

final class StyleExtractor {
	// MARK: - Stored variables
	
	private var generatedRawTextStylesFile: File!
	private var generatedRawColorStylesFile: File!
	private var sketchDocument: SketchDocument!
	
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
		return sketchDocument.layerTextStyles.objects
			.flatMap { textStyleObject -> TextStyle? in
				guard
					let color = textStyleObject.value.textStyle.encodedAttributes.color.color,
					let colorStyle = ColorStyle.colorStyle(for: color, in: latestColorStyles)
				else {
					print("⚠️ \(textStyleObject.name) does not use a color from the shared colour scheme")
					return nil
				}
				return TextStyle(textStyleObject: textStyleObject, colorStyle: colorStyle)
		}
	}()
	lazy var latestColorStyles: [ColorStyle] = {
		return sketchDocument.layerStyles.objects
			.flatMap({ ColorStyle(colorStyleObject: $0) })
	}()
	
	// MARK: - Initializer
	
	init(
		generatedRawTextStylesFile: File,
		generatedRawColorStylesFile: File,
		sketchDocument: SketchDocument
	) {
		self.generatedRawTextStylesFile = generatedRawTextStylesFile
		self.generatedRawColorStylesFile = generatedRawColorStylesFile
		self.sketchDocument = sketchDocument
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
		print("Found previously exported styles at v\(previousVersion.stringRepresentation)")
		return (versionedTextStyles.textStyles, versionedColorStyles.colorStyles, previousVersion)
	}
	
	private func getPreviousStylesVersion(
		versionedTextStyle: VersionedStyle.Text,
		versionedColorStyle: VersionedStyle.Color
	) -> Version {
		let textVersion = versionedTextStyle.version
		let colorVersion = versionedColorStyle.version
		if textVersion != colorVersion {
			print("Mismatching versions: \(textVersion.stringRepresentation) (Text) and \(colorVersion.stringRepresentation) (Color)")
		}
		return textVersion
	}
}
