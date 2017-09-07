//
//  PullRequestBody.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation

struct PullRequestBodyGenerator {
	// MARK: - Stored properties
	
	private let headingGenerator: CodeGenerator
	private let styleNameGenerator: CodeGenerator
	private let addedStyleTableGenerator: CodeGenerator
	private let updatedStyleTableGenerator: CodeGenerator
	private let deprecatedStylesTableGenerator: CodeGenerator
	
	// MARK: - Initializer
	
	init(
		headingTemplate: Template,
		styleNameTemplate: Template,
		addedStyleTableTemplate: Template,
		updatedStyleTableTemplate: Template,
		deprecatedStylesTableTemplate: Template
	) throws {
		self.headingGenerator = try CodeGenerator(template: headingTemplate)
		self.styleNameGenerator = try CodeGenerator(template: styleNameTemplate)
		self.addedStyleTableGenerator = try CodeGenerator(template: addedStyleTableTemplate)
		self.updatedStyleTableGenerator = try CodeGenerator(template: updatedStyleTableTemplate)
		self.deprecatedStylesTableGenerator = try CodeGenerator(template: deprecatedStylesTableTemplate)
	}
	
	// MARK: - Body
	
	private typealias OldAndNewStyles = (old: [Style], new: [Style])
	
	func body(
		fromOldColorStyles oldColorStyles: [ColorStyle],
		newColorStyles: [ColorStyle],
		oldTextStyles: [TextStyle],
		newTextStyles: [TextStyle]
	) -> String {
		let oldAndNewColorStyles: OldAndNewStyles = (oldColorStyles, newColorStyles)
		let oldAndNewTextStyles: OldAndNewStyles = (oldTextStyles, newTextStyles)
		let allStyleGroups: [OldAndNewStyles] = [oldAndNewColorStyles, oldAndNewTextStyles]
		
		var sections: [String?] = []
		sections.append(
			contentsOf: allStyleGroups
				.map { addedStyles(oldStyles: $0.old, newStyles: $0.new) }
				.map { addedStylesSection(for: $0) }
		)
		sections.append(
			contentsOf: allStyleGroups
				.map { updatedStyles(oldStyles: $0.old, newStyles: $0.new) }
				.map { updatedStylesSection(for: $0) }
		)
		sections.append(
			contentsOf: allStyleGroups
				.map { removedStyles(oldStyles: $0.old, newStyles: $0.new) }
				.map { removedStylesSection(for: $0) }
		)
		
		return sections
			.flatMap({ $0 })
			.joined(separator: "\n")
	}
	
	// MARK: - Sections
	
	private func addedStylesSection(for styles: [AddedStyle]) -> String? {
		guard !styles.isEmpty else {
			return nil
		}
		
		let generatedHeading = self.generatedHeading(withName: "Added Styles")

		let generatedAddedStyles: [String] = styles.map { style in
			let heading = styleNameGenerator.generatedCode(for: style)
			let table = addedStyleTableGenerator.generatedCode(for: [style.attributes])
			return heading + "\n" + table
		}
		return generatedHeading + "\n" + generatedAddedStyles.joined(separator: "\n") + "\n"
	}

	private func updatedStylesSection(for styles: [UpdatedStyle]) -> String? {
		guard !styles.isEmpty else {
			return nil
		}
		
		let generatedHeading = self.generatedHeading(withName: "Updated Styles")

		let generatedUpdatedStyles: [String] = styles.map { style in
			let heading = styleNameGenerator.generatedCode(for: style)
			let table = updatedStyleTableGenerator.generatedCode(for: [style.updatedAttributes])
			return heading + "\n" + table
		}
		return generatedHeading + "\n" + generatedUpdatedStyles.joined(separator: "\n") + "\n"
	}
	
	private func removedStylesSection(for styles: [RemovedStyle]) -> String? {
		guard !styles.isEmpty else {
			return nil
		}
		
		let generatedHeading = self.generatedHeading(withName: "Removed Styles")
		
		let generatedRemovedStyles: [String] = styles.map { style in
			let heading = styleNameGenerator.generatedCode(for: style)
			return heading + "\n"
		}
		return generatedHeading + "\n" + generatedRemovedStyles.joined(separator: "\n") + "\n"
	}
	
	// MARK: - Utilities
	
	private func generatedHeading(withName name: String) -> String {
		let heading = Heading(name: name)
		return headingGenerator.generatedCode(for: heading)
	}
	
	private func addedStyles(oldStyles: [Style], newStyles: [Style]) -> [AddedStyle] {
		return newStyles.flatMap { newStyle in
			guard oldStyles.first(where: { $0.identifier == newStyle.identifier }) == nil else {
				return nil
			}
			return AddedStyle(style: newStyle)
		}
	}
	
	// TODO: You can probably get this from the data found out already...
	private func updatedStyles(oldStyles: [Style], newStyles: [Style]) -> [UpdatedStyle] {
		return newStyles.flatMap { newStyle in
			guard let oldStyle = oldStyles
				.first(where: { $0.identifier == newStyle.identifier }) else {
					return nil
			}
			return UpdatedStyle(oldStyle: oldStyle, newStyle: newStyle)
		}
	}
	
	private func removedStyles(oldStyles: [Style], newStyles: [Style]) -> [RemovedStyle] {
		return oldStyles.flatMap { newStyle in
			guard newStyles.first(where: { $0.identifier == newStyle.identifier }) == nil else {
				return nil
			}
			return RemovedStyle(style: newStyle)
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
