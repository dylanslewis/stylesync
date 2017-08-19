#!/usr/bin/swift
//
//  main.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 09/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Cocoa

let commandLineArguments = CommandLine.arguments.dropFirst()
guard
	commandLineArguments.count == 2,
	let sketchDocumentPathString = commandLineArguments.first,
	let exportDirectoryPathString = commandLineArguments.last
else {
	print("First parameter should be Sketch file's document.json and second should be export path.")
	fatalError()
}

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
let allColorStyles = newColorStyles + deprecatedColorStyles

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
let allTextStyles = newTextStyles + deprecatedTextStyles

let iOSSwiftColorStyleTemplateURL = URL(fileURLWithPath: "/Users/dylanslewis/Developer/SketchStyleExporter/Development/SketchStyleExporter/SketchStyleExporter/Templates/ColorStyles/iOSSwift")
let iOSSwiftColorStyleTemplateData = try! Data(contentsOf: iOSSwiftColorStyleTemplateURL)
let iOSSwiftColorStyleTemplate: Template = String.init(data: iOSSwiftColorStyleTemplateData, encoding: .utf8)!

let iOSSwiftTextStyleTemplateURL = URL(fileURLWithPath: "/Users/dylanslewis/Developer/SketchStyleExporter/Development/SketchStyleExporter/SketchStyleExporter/Templates/TextStyles/iOSSwift")
let iOSSwiftTextStyleTemplateData = try! Data(contentsOf: iOSSwiftTextStyleTemplateURL)
let iOSSwiftTextStyleTemplate: Template = String.init(data: iOSSwiftTextStyleTemplateData, encoding: .utf8)!

let colorStyleCodeGenerator = CodeGenerator(template: iOSSwiftColorStyleTemplate, codeTemplateReplacables: [allColorStyles])
let generatedColorStylesCode = colorStyleCodeGenerator.generatedCode

let textStyleCodeGenerator = CodeGenerator(template: iOSSwiftTextStyleTemplate, codeTemplateReplacables: [allTextStyles])
let generatedTextStylesCode = textStyleCodeGenerator.generatedCode


var generatedColorStylesFilePath = exportDirectoryPath.appendingPathComponent("ColorStyles")
if let fileExtension = colorStyleCodeGenerator.fileExtension {
	generatedColorStylesFilePath = generatedColorStylesFilePath.appendingPathExtension(fileExtension)
}

var generatedTextStylesFilePath = exportDirectoryPath.appendingPathComponent("TextStyles")
if let fileExtension = textStyleCodeGenerator.fileExtension {
	generatedTextStylesFilePath = generatedTextStylesFilePath.appendingPathExtension(fileExtension)
}

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
