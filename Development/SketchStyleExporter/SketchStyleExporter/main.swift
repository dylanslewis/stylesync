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

let colorStyles = sketchDocument.layerStyles.objects.flatMap(ColorStyle.init)
let textStyles = sketchDocument.layerTextStyles.objects.flatMap { textStyleObject -> TextStyle? in
	guard
		let color = textStyleObject.value.textStyle.encodedAttributes.color.color,
		let colorStyle = ColorStyle.colorStyle(for: color, in: colorStyles)
	else {
		print("⚠️ \(textStyleObject.name) does not use a color from the shared colour scheme")
		return nil
	}
	return TextStyle(textStyleObject: textStyleObject, colorStyle: colorStyle)
}

let iOSSwiftColorStyleTemplateURL = URL(fileURLWithPath: "/Users/dylanslewis/Developer/SketchStyleExporter/Development/SketchStyleExporter/SketchStyleExporter/Templates/ColorStyles/iOSSwift")
let iOSSwiftColorStyleTemplateData = try! Data(contentsOf: iOSSwiftColorStyleTemplateURL)
let iOSSwiftColorStyleTemplate: Template = String.init(data: iOSSwiftColorStyleTemplateData, encoding: .utf8)!

let iOSSwiftTextStyleTemplateURL = URL(fileURLWithPath: "/Users/dylanslewis/Developer/SketchStyleExporter/Development/SketchStyleExporter/SketchStyleExporter/Templates/TextStyles/iOSSwift")
let iOSSwiftTextStyleTemplateData = try! Data(contentsOf: iOSSwiftTextStyleTemplateURL)
let iOSSwiftTextStyleTemplate: Template = String.init(data: iOSSwiftTextStyleTemplateData, encoding: .utf8)!

let colorStyleCodeGenerator = CodeGenerator(template: iOSSwiftColorStyleTemplate, codeTemplateReplacables: [colorStyles])
let generatedColorStylesCode = colorStyleCodeGenerator.generatedCode

let textStyleCodeGenerator = CodeGenerator(template: iOSSwiftTextStyleTemplate, codeTemplateReplacables: [textStyles])
let generatedTextStylesCode = textStyleCodeGenerator.generatedCode

let exportDirectoryPath = URL(fileURLWithPath: exportDirectoryPathString)

let generatedColorStylesFilePath = exportDirectoryPath.appendingPathComponent("ColorStyles.swift")
let generatedTextStylesFilePath = exportDirectoryPath.appendingPathComponent("TextStyles.swift")

let rawStylesFilePath = exportDirectoryPath.appendingPathComponent("ExportedStyles.json")
let version: Version
if
	let previousExportedStylesData = try? Data(contentsOf: rawStylesFilePath),
	let previousExportedStyles = try? decoder.decode(VersionedStyles.self, from: previousExportedStylesData)
{
	let didTextStylesChange = previousExportedStyles.textStyles != textStyles
	let didColorStylesChange = previousExportedStyles.colorStyles != colorStyles
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
	colorStyles: colorStyles,
	textStyles: textStyles
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
