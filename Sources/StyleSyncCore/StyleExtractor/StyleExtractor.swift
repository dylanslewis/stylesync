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
		let nonNamespacedLayerTextStyles = sketchDocument.layerTextStyles.objects.filter({ textStyleObject -> Bool in
			return !textStyleObject.name.contains("/")
		})
		let namespacedLayerTextStyles = sketchDocument.layerTextStyles.objects.filter({ textStyleObject -> Bool in
			return textStyleObject.name.contains("/")
		})
		
		var namespacedStylesForName: [String: [SketchDocument.TextStyles.Object]] = [:]
		for namespacedLayerTextStyle in namespacedLayerTextStyles {
			guard let styleName = namespacedLayerTextStyle.name.split(separator: "/").first else {
				continue
			}
			var existingStyles = namespacedStylesForName[String(styleName)] ?? []
			existingStyles.append(namespacedLayerTextStyle)
			
			namespacedStylesForName[String(styleName)] = existingStyles
		}
		
		let convertedNonNamespacedStyles = nonNamespacedLayerTextStyles.compactMap { textStyleObject -> TextStyle? in
			let color = textStyleObject.value.textStyle.encodedAttributes.color
			guard let colorStyle = ColorStyle.colorStyle(for: color, in: latestColorStyles) else {
				ErrorManager.log(warning: "\(textStyleObject.name) does not use a color from the shared colour scheme")
				return nil
			}
			return TextStyle(textStyleObject: textStyleObject, colorStyle: colorStyle)
		}
		
		let convertedNamespacedStyles = namespacedStylesForName.compactMap({ (name, textStyleObjects) -> TextStyle? in
			return TextStyle(name: name, textStyleObjects: textStyleObjects)
		})
		
		return convertedNonNamespacedStyles + convertedNamespacedStyles
	}()
	lazy var latestColorStyles: [ColorStyle] = {
		return sketchDocument.layerStyles.objects
			.compactMap({ ColorStyle(colorStyleObject: $0) })
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
