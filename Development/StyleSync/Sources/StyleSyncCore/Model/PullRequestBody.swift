//
//  PullRequestBody.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation

struct PullRequestBodyGenerator {
	private let headingGenerator: CodeGenerator
	private let styleNameGenerator: CodeGenerator
	private let newStyleTableGenerator: CodeGenerator
	private let updatedStyleTableGenerator: CodeGenerator
	private let deprecatedStylesTableGenerator: CodeGenerator
	
	init(
		headingTemplate: Template,
		styleNameTemplate: Template,
		newStyleTableTemplate: Template,
		updatedStyleTableTemplate: Template,
		deprecatedStylesTableTemplate: Template
	) throws {
		self.headingGenerator = try CodeGenerator(template: headingTemplate)
		self.styleNameGenerator = try CodeGenerator(template: styleNameTemplate)
		self.newStyleTableGenerator = try CodeGenerator(template: newStyleTableTemplate)
		self.updatedStyleTableGenerator = try CodeGenerator(template: updatedStyleTableTemplate)
		self.deprecatedStylesTableGenerator = try CodeGenerator(template: deprecatedStylesTableTemplate)
	}
	
	func body(
		fromOldColorStyles oldColorStyles: [ColorStyle],
		newColorStyles: [ColorStyle],
		oldTextStyles: [TextStyle],
		newTextStyles: [TextStyle]
	) throws -> String {
		let updatedColorStyles = updatedStyles(oldStyles: oldColorStyles, newStyles: newColorStyles)
		let updatedTextStyles = updatedStyles(oldStyles: oldTextStyles, newStyles: newTextStyles)
		let allUpdatedStyles = updatedColorStyles + updatedTextStyles

		let newColorStyles = newStyles(oldStyles: oldColorStyles, newStyles: newColorStyles)
		let newTextStyles = newStyles(oldStyles: oldTextStyles, newStyles: newTextStyles)
		let allNewStyles = newColorStyles + newTextStyles
		
		var body: String = ""
		if let newStylesSection = self.newStylesSection(forStyles: allNewStyles) {
			body.append(contentsOf: newStylesSection)
		}
		
		if let updatedStylesSection = self.updatedStylesSection(forUpdatedStyles: allUpdatedStyles) {
			body.append(contentsOf: updatedStylesSection)
		}
		return body
	}
	
	private func newStylesSection(forStyles styles: [NewStyle]) -> String? {
		guard !styles.isEmpty else {
			return nil
		}
		
		let heading = Heading(name: "New Styles")
		let generatedHeading = headingGenerator.generatedCode(for: heading)
		
		let newStyles: [String] = styles.map { newStyle in
			let heading = styleNameGenerator.generatedCode(for: newStyle)
			let table = newStyleTableGenerator.generatedCode(for: [newStyle.attributes])
			return heading + "\n" + table
		}
		return generatedHeading + "\n" + newStyles.joined(separator: "\n") + "\n"
	}

	private func updatedStylesSection(forUpdatedStyles updatedStyles: [UpdatedStyle]) -> String? {
		guard !updatedStyles.isEmpty else {
			return nil
		}
		
		let heading = Heading(name: "Updated Styles")
		let generatedHeading = headingGenerator.generatedCode(for: heading)
		
		let generatedUpdatedStyles: [String] = updatedStyles.map { updatedStyle in
			let heading = styleNameGenerator.generatedCode(for: updatedStyle)
			let table = updatedStyleTableGenerator.generatedCode(for: [updatedStyle.updatedAttributes])
			return heading + "\n" + table
		}
		return generatedHeading + "\n" + generatedUpdatedStyles.joined(separator: "\n") + "\n"
	}
	
	private func newStyles<S: Style>(oldStyles: [S], newStyles: [S]) -> [NewStyle] {
		return newStyles.flatMap { newStyle in
			guard oldStyles.first(where: { $0.identifier == newStyle.identifier }) == nil else {
				return nil
			}
			return NewStyle(style: newStyle)
		}
	}
	
	// TODO: You can probably get this from the data found out already...
	private func updatedStyles<S: Style>(oldStyles: [S], newStyles: [S]) -> [UpdatedStyle] {
		return newStyles.flatMap { newStyle in
			guard let oldStyle = oldStyles
				.first(where: { $0.identifier == newStyle.identifier }) else {
					return nil
			}
			return UpdatedStyle(oldStyle: oldStyle, newStyle: newStyle)
		}
	}
}

extension PullRequestBodyGenerator {
	struct Heading {
		let name: String
	}
}

extension PullRequestBodyGenerator.Heading: CodeTemplateReplacable {
	static let declarationName: String = "headingDeclaration"
	
	var replacementDictionary: [String : String] {
		return ["headingName": name]
	}
}
