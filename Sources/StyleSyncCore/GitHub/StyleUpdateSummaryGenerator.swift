//
//  StyleUpdateSummaryGenerator.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation

struct StyleUpdateSummaryGenerator {
	// MARK: - Constant
	
	private enum HeadingName {
		static let added = "✅ Added Styles"
		static let updated = "💅 Updated Styles"
		static let removed = "⛔ Removed Styles"
		static let deprecated = "⚠️ Deprecated Styles"
	}
	
	// MARK: - Stored properties
	
	private let headingGenerator: CodeGenerator
	private let styleNameGenerator: CodeGenerator
	private let addedStyleTableGenerator: CodeGenerator
	private let updatedStyleTableGenerator: CodeGenerator
	private let deprecatedStylesTableGenerator: CodeGenerator
	private let shouldPrintStyleSyncLink: Bool
	
	// MARK: - Initializer
	
	init(
		headingTemplate: Template,
		styleNameTemplate: Template,
		addedStyleTableTemplate: Template,
		updatedStyleTableTemplate: Template,
		deprecatedStylesTableTemplate: Template,
		shouldPrintStyleSyncLink: Bool = true
	) throws {
		self.headingGenerator = try CodeGenerator(template: headingTemplate)
		self.styleNameGenerator = try CodeGenerator(template: styleNameTemplate)
		self.addedStyleTableGenerator = try CodeGenerator(template: addedStyleTableTemplate)
		self.updatedStyleTableGenerator = try CodeGenerator(template: updatedStyleTableTemplate)
		self.deprecatedStylesTableGenerator = try CodeGenerator(template: deprecatedStylesTableTemplate)
		self.shouldPrintStyleSyncLink = shouldPrintStyleSyncLink
	}
	
	// MARK: - Body
	
	private typealias OldAndNewStyles = (old: [Style], new: [Style])
	
	func body(
		fromOldColorStyles oldColorStyles: [ColorStyle],
		newColorStyles: [ColorStyle],
		oldTextStyles: [TextStyle],
		newTextStyles: [TextStyle],
		fileNamesForDeprecatedStyleNames: [String: [String]]
	) -> String {
		let oldAndNewColorStyles: OldAndNewStyles = (oldColorStyles, newColorStyles)
		let oldAndNewTextStyles: OldAndNewStyles = (oldTextStyles, newTextStyles)
		let allStyleGroups: [OldAndNewStyles] = [oldAndNewColorStyles, oldAndNewTextStyles]
		
		let allAddedStyles = allStyleGroups
			.map { addedStyles(oldStyles: $0.old, newStyles: $0.new) }
			.flatMap { $0 }
		let allUpdatedStyles = allStyleGroups
			.map { updatedStyles(oldStyles: $0.old, newStyles: $0.new) }
			.flatMap { $0 }
		let allRemovedStyles = allStyleGroups
			.map { removedStyles(oldStyles: $0.old, newStyles: $0.new) }
			.flatMap { $0 }
		let allDeprecatedStyles = deprecatedStyles(
			forFileNamesForStyle: fileNamesForDeprecatedStyleNames
		)
		var sections: [String?] = []
		sections.append(addedStylesSection(for: allAddedStyles))
		sections.append(updatedStylesSection(for: allUpdatedStyles))
		sections.append(removedStylesSection(for: allRemovedStyles))
		sections.append(deprecatedStylesSection(for: allDeprecatedStyles))
		if shouldPrintStyleSyncLink {
			sections.append(gitHubLinkSection)
		}

		return sections
			.flatMap({ $0 })
			.joined(separator: "\n")
	}
	
	// MARK: - Sections
	
	private func addedStylesSection(for styles: [AddedStyle]) -> String? {
		guard !styles.isEmpty else {
			return nil
		}
		
		let generatedHeading = self.generatedHeading(withName: HeadingName.added)

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
		
		let generatedHeading = self.generatedHeading(withName: HeadingName.updated)

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
		
		let generatedHeading = self.generatedHeading(withName: HeadingName.removed)
		
		let generatedRemovedStyles: [String] = styles.map { style in
			let heading = styleNameGenerator.generatedCode(for: style)
			return heading + "\n"
		}
		return generatedHeading + "\n" + generatedRemovedStyles.joined(separator: "\n") + "\n"
	}
	
	private func deprecatedStylesSection(for styles: [DeprecatedStyle]) -> String? {
		guard !styles.isEmpty else {
			return nil
		}
		
		let generatedHeading = self.generatedHeading(withName: HeadingName.deprecated)
		
		let generatedDeprecatedStyles: [String] = styles.map { deprecatedStylesTableGenerator.generatedCode(for: $0) }
		return generatedHeading + "\n" + generatedDeprecatedStyles.joined(separator: "\n") + "\n"
	}
	
	private var gitHubLinkSection: String {
		return """
		##
		<p align="right" data-meta="generated_by_stylesync">
		Generated by <a href="https://github.com/dylanslewis/StyleSync">Style Sync</a>
		</p>
		"""
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
		return oldStyles
			.filter({ !$0.isDeprecated })
			.flatMap { newStyle in
				guard newStyles.first(where: { $0.identifier == newStyle.identifier }) == nil else {
					return nil
				}
				return RemovedStyle(style: newStyle)
			}
	}
	
	private func deprecatedStyles(forFileNamesForStyle fileNamesForStyleName: [String: [String]]) -> [DeprecatedStyle] {
		return fileNamesForStyleName.flatMap({ DeprecatedStyle(styleName: $0.0, fileNames: $0.1) })
	}
}

extension StyleUpdateSummaryGenerator {
	struct Heading {
		let name: String
	}
}

extension StyleUpdateSummaryGenerator.Heading: CodeTemplateReplacable {
	static let declarationName: String = "headingDeclaration"
	
	var replacementDictionary: [String : String] {
		return ["headingName": name]
	}
}
