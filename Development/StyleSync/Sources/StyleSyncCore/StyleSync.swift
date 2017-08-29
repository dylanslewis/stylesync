//
//  main.swift
//  StyleSync
//
//  Created by Dylan Lewis on 09/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

public final class StyleSync {
	private let arguments: [String]
	
	public init(arguments: [String] = CommandLine.arguments) {
		self.arguments = arguments
	}
	
	public func run() throws {
		guard arguments.count == 6 else {
			print("First parameter should be Sketch file's document.json and second should be export path.")
			fatalError()
		}

		let sketchDocumentPathString = arguments[1]
		let projectDirectoryPathString = arguments[2]
		let exportDirectoryPathString = arguments[3]
		let colorStyleTemplateURLString = arguments[4]
		let textStyleTemplateURLString = arguments[5]
		
		let decoder = JSONDecoder()
		let sketchDocumentPath = URL(fileURLWithPath: sketchDocumentPathString)
		guard
			let sketchDocumentData = try? Data(contentsOf: sketchDocumentPath),
			let sketchDocument = try? decoder.decode(SketchDocument.self, from: sketchDocumentData)
			else {
				print("Failed to extract JSON data from Sketch file's document.json")
				fatalError()
		}
		
		let exportDirectoryPath = URL(fileURLWithPath: exportDirectoryPathString)
		let rawStylesFilePath = exportDirectoryPath.appendingPathComponent("ExportedStyles.json")
		
		let previousExportedStyles: VersionedStyles?
		let previousExportedColorStyles: [ColorStyle]
		let previousExportedTextStyles: [TextStyle]
		if
			let previousExportedStylesData = try? Data(contentsOf: rawStylesFilePath),
			let versionedStyles = try? decoder.decode(VersionedStyles.self, from: previousExportedStylesData)
		{
			previousExportedStyles = versionedStyles
			previousExportedColorStyles = versionedStyles.colorStyles
			previousExportedTextStyles = versionedStyles.textStyles
		} else {
			previousExportedStyles = nil
			previousExportedColorStyles = []
			previousExportedTextStyles = []
		}
		
		let newColorStyles = sketchDocument.layerStyles.objects.flatMap({ ColorStyle(colorStyleObject: $0, isDeprecated: false) })
		var deprecatedColorStyles = previousExportedColorStyles
			.filter { colorStyle -> Bool in
				return newColorStyles.contains(where: { $0.identifier == colorStyle.identifier }) == false
			}
			.map { colorStyle -> ColorStyle in
				return colorStyle.deprecated
		}
		
		let newTextStyles = sketchDocument.layerTextStyles.objects.flatMap { textStyleObject -> TextStyle? in
			guard
				let color = textStyleObject.value.textStyle.encodedAttributes.color.color,
				let colorStyle = ColorStyle.colorStyle(for: color, in: newColorStyles)
				else {
					print("⚠️ \(textStyleObject.name) does not use a color from the shared colour scheme")
					return nil
			}
			return TextStyle(textStyleObject: textStyleObject, colorStyle: colorStyle, isDeprecated: false)
		}
		var deprecatedTextStyles = previousExportedTextStyles
			.filter { textStyle -> Bool in
				return newTextStyles.contains(where: { $0.identifier == textStyle.identifier }) == false
			}
			.map { textStyle -> TextStyle in
				return textStyle.deprecated
		}
		
		let iOSSwiftColorStyleTemplateURL = URL(fileURLWithPath: colorStyleTemplateURLString)
		let iOSSwiftTextStyleTemplateURL = URL(fileURLWithPath: textStyleTemplateURLString)
		
		let iOSSwiftColorStyleTemplateData: Data
		let iOSSwiftTextStyleTemplateData: Data
		do {
			iOSSwiftColorStyleTemplateData = try Data(contentsOf: iOSSwiftColorStyleTemplateURL)
			iOSSwiftTextStyleTemplateData = try Data(contentsOf: iOSSwiftTextStyleTemplateURL)
		} catch {
			print(error)
			fatalError()
		}
		
		let iOSSwiftColorStyleTemplate: Template = String.init(data: iOSSwiftColorStyleTemplateData, encoding: .utf8)!
		let iOSSwiftTextStyleTemplate: Template = String.init(data: iOSSwiftTextStyleTemplateData, encoding: .utf8)!
		
		let colorStyleParser = StyleParser(newStyles: newColorStyles, currentStyles: previousExportedColorStyles)
		let textStyleParser = StyleParser(newStyles: newTextStyles, currentStyles: previousExportedTextStyles)
		
		let currentAndMigratedColorStyles = colorStyleParser.currentAndMigratedStyles
		let currentAndMigratedTextStyles = textStyleParser.currentAndMigratedStyles
		
		// Code generators
		
		let colorStyleCodeGenerator = try! CodeGenerator(template: iOSSwiftColorStyleTemplate)
		let textStyleCodeGenerator = try! CodeGenerator(template: iOSSwiftTextStyleTemplate)
		
		let generatedColorStylesFilePath = exportDirectoryPath
			.appendingPathComponent("ColorStyles")
			.appendingPathExtension(colorStyleCodeGenerator.fileExtension)
		
		let generatedTextStylesFilePath = exportDirectoryPath
			.appendingPathComponent("TextStyles")
			.appendingPathExtension(textStyleCodeGenerator.fileExtension)
		
		var usedDeprecatedColorStyles: Set<ColorStyle> = []
		var usedDeprecatedTextStyles: Set<TextStyle> = []
		
		if !(currentAndMigratedColorStyles.isEmpty && currentAndMigratedTextStyles.isEmpty) {
			let fileManager = FileManager.default
			let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: projectDirectoryPathString)!
			while let element = enumerator.nextObject() as? String {
				// Iterate over this once for each style that's being replaced.
				let fullPath = projectDirectoryPathString + element
				guard
					element.hasSuffix(colorStyleCodeGenerator.fileExtension),
					element.hasSuffix(textStyleCodeGenerator.fileExtension),
					fullPath != generatedColorStylesFilePath.relativeString,
					fullPath != generatedTextStylesFilePath.relativeString
					else {
						// Skip over files that don't match the extension of the template,
						// and the files generated by this script.
						continue
				}
				
				guard
					let fileData = fileManager.contents(atPath: fullPath),
					var fileContents = String(data: fileData, encoding: .utf8)
					else {
						print("Unable to open file at: \(fullPath)")
						continue
				}
				
				deprecatedColorStyles.forEach({ colorStyle in
					if fileContents.contains(colorStyle.codeName) {
						usedDeprecatedColorStyles.insert(colorStyle)
					}
				})
				
				deprecatedTextStyles.forEach({ textStyle in
					if fileContents.contains(textStyle.codeName) {
						usedDeprecatedTextStyles.insert(textStyle)
					}
				})
				
				for (currentColorStyle, migratedColorStyle) in currentAndMigratedColorStyles {
					fileContents = fileContents.replacingOccurrences(of: currentColorStyle.codeName, with: migratedColorStyle.codeName)
				}
				
				for (currentTextStyle, migratedTextStyle) in currentAndMigratedTextStyles {
					fileContents = fileContents.replacingOccurrences(of: currentTextStyle.codeName, with: migratedTextStyle.codeName)
				}
				
				guard let updatedFileContentsData = fileContents.data(using: .utf8) else {
					print("Failed to create data for file at \(fullPath).")
					continue
				}
				
				let fullPathURL = URL(fileURLWithPath: fullPath)
				
				do {
					try updatedFileContentsData.write(to: fullPathURL, options: .atomic)
				} catch {
					print(error)
				}
			}
		}
		
		// Only styles that are still in the project should be deprecated, and any
		// others removed completely.
		deprecatedColorStyles = deprecatedColorStyles
			.filter({ return usedDeprecatedColorStyles.contains($0) })
			.filter({ colorStyle -> Bool in
				// If a style is removed but another is added with the same name, then
				// remove the deprecated one to avoid compilation issues.
				if newColorStyles
					.contains(where: { return $0.codeName == colorStyle.codeName }) {
					print("Style with name \(colorStyle.codeName) was removed and added with a different name.")
					return false
				} else {
					return true
				}
			})
		deprecatedTextStyles = deprecatedTextStyles
			.filter({ return usedDeprecatedTextStyles.contains($0) })
			.filter({ textStyle -> Bool in
				// If a style is removed but another is added with the same name, then
				// remove the deprecated one to avoid compilation issues.
				if newTextStyles
					.contains(where: { return $0.codeName == textStyle.codeName }) {
					print("Style with name \(textStyle.codeName) was removed and added with a different name.")
					return false
				} else {
					return true
				}
			})
		
		let allColorStyles = newColorStyles + deprecatedColorStyles
		let allTextStyles = newTextStyles + deprecatedTextStyles
		
		let generatedColorStylesCode = colorStyleCodeGenerator.generatedCode(for: [allColorStyles])
		let generatedTextStylesCode = textStyleCodeGenerator.generatedCode(for: [allTextStyles])
		
		let version: Version
		if let previousExportedStyles = previousExportedStyles {
			let didTextStylesChange = previousExportedStyles.textStyles != newTextStyles
			let didColorStylesChange = previousExportedStyles.colorStyles != newColorStyles
			switch (didTextStylesChange, didColorStylesChange) {
			case (true, _):
				version = previousExportedStyles.version.incrementingMajor()
			case (false, true):
				version = previousExportedStyles.version.incrementingMinor()
			case (false, false):
				version = previousExportedStyles.version
			}
		} else {
			version = .firstVersion
		}
		
		let versionedStyles = VersionedStyles(
			version: version,
			colorStyles: allColorStyles,
			textStyles: allTextStyles
		)
		let encoder = JSONEncoder()
		let rawStylesData = try! encoder.encode(versionedStyles)
		
		guard
			let generatedColorStylesData = generatedColorStylesCode.data(using: .utf8),
			let generatedTextStylesData = generatedTextStylesCode.data(using: .utf8)
			else {
				fatalError()
		}
		
		do {
			try generatedColorStylesData.write(to: generatedColorStylesFilePath, options: .atomic)
			try generatedTextStylesData.write(to: generatedTextStylesFilePath, options: .atomic)
			try rawStylesData.write(to: rawStylesFilePath, options: .atomic)
		} catch {
			print(error)
		}
	}
}
