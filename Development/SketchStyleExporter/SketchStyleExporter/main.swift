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
guard commandLineArguments.count == 2 else {
	print("First argument should be document.json and second should be export location")
	fatalError()
}

guard
	let sketchDocumentPathString = commandLineArguments.first,
	let exportDirectoryPathString = commandLineArguments.last
else {
	print("Pass the sketch file as the first argument")
	fatalError()
}

let sketchDocumentPath = URL(fileURLWithPath: sketchDocumentPathString)
guard let sketchDocumentData = try? Data(contentsOf: sketchDocumentPath) else {
	print("Failed to extract JSON data")
	fatalError()
}

let decoder = JSONDecoder()
guard let sketchDocument = try? decoder.decode(SketchDocument.self, from: sketchDocumentData) else {
	print("Failed to decode JSON data")
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

let rawColorStylesFilePath = exportDirectoryPath.appendingPathComponent("ColorStyles.json")
let rawTextStylesFilePath = exportDirectoryPath.appendingPathComponent("TextStyles.json")

let encoder = JSONEncoder()
let rawColorStylesData = try! encoder.encode(colorStyles)
let rawTextStylesData = try! encoder.encode(textStyles)

guard
	let generatedColorStylesData = generatedColorStylesCode.data(using: .utf8),
	let generatedTextStylesData = generatedTextStylesCode.data(using: .utf8)
else {
	fatalError()
}
	
do {
	try generatedColorStylesData.write(to: generatedColorStylesFilePath, options: .atomic)
	try generatedTextStylesData.write(to: generatedTextStylesFilePath, options: .atomic)
	try rawColorStylesData.write(to: rawColorStylesFilePath, options: .atomic)
	try rawTextStylesData.write(to: rawTextStylesFilePath, options: .atomic)
} catch {
	print(error)
}
