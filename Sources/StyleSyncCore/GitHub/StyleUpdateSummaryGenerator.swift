//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

struct StyleUpdateSummaryGenerator {
	// MARK: - Constant
	
	private enum HeadingName {
		static let added = "✅  Added Styles"
		static let updated = "💅  Updated Styles"
		static let removed = "⛔  Removed Styles"
		static let deprecated = "⚠️  Deprecated Styles"
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
		fileExtension: FileType,
		shouldPrintStyleSyncLink: Bool = true
	) throws {
		self.headingGenerator = CodeGenerator(template: headingTemplate, fileExtension: fileExtension)
		self.styleNameGenerator = CodeGenerator(template: styleNameTemplate, fileExtension: fileExtension)
		self.addedStyleTableGenerator = CodeGenerator(template: addedStyleTableTemplate, fileExtension: fileExtension)
		self.updatedStyleTableGenerator = CodeGenerator(template: updatedStyleTableTemplate, fileExtension: fileExtension)
		self.deprecatedStylesTableGenerator = CodeGenerator(template: deprecatedStylesTableTemplate, fileExtension: fileExtension)
		self.shouldPrintStyleSyncLink = shouldPrintStyleSyncLink
	}
	
	// MARK: - Body
	
	private typealias OldAndNewStyles = (old: [CodeTemplateReplacableStyle], new: [CodeTemplateReplacableStyle])
	
	func body(
		fromOldColorStyles oldColorStyles: [CodeTemplateReplacableStyle],
		newColorStyles: [CodeTemplateReplacableStyle],
		oldTextStyles: [CodeTemplateReplacableStyle],
		newTextStyles: [CodeTemplateReplacableStyle],
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
			.compactMap({ $0 })
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
		Generated by <b><a href="https://github.com/dylanslewis/stylesync">stylesync</a></b>
		</p>
		"""
	}
	
	// MARK: - Utilities
	
	private func generatedHeading(withName name: String) -> String {
		let heading = Heading(name: name)
		return headingGenerator.generatedCode(for: heading)
	}
	
	private func addedStyles(oldStyles: [CodeTemplateReplacableStyle], newStyles: [CodeTemplateReplacableStyle]) -> [AddedStyle] {
		return newStyles.compactMap { newStyle in
			guard oldStyles.first(where: { $0.identifier == newStyle.identifier }) == nil else {
				return nil
			}
			return AddedStyle(style: newStyle)
		}
	}
	
	private func updatedStyles(oldStyles: [CodeTemplateReplacableStyle], newStyles: [CodeTemplateReplacableStyle]) -> [UpdatedStyle] {
		return newStyles.compactMap { newStyle in
			guard let oldStyle = oldStyles
				.first(where: { $0.identifier == newStyle.identifier }) else {
					return nil
			}
			return UpdatedStyle(oldStyle: oldStyle, newStyle: newStyle)
		}
	}
	
	private func removedStyles(oldStyles: [CodeTemplateReplacableStyle], newStyles: [CodeTemplateReplacableStyle]) -> [RemovedStyle] {
		return oldStyles
			.filter({ !$0.isDeprecated })
			.compactMap { newStyle in
				guard newStyles.first(where: { $0.identifier == newStyle.identifier }) == nil else {
					return nil
				}
				return RemovedStyle(style: newStyle)
			}
	}
	
	private func deprecatedStyles(forFileNamesForStyle fileNamesForStyleName: [String: [String]]) -> [DeprecatedStyle] {
		return fileNamesForStyleName.compactMap({ DeprecatedStyle(styleName: $0.0, fileNames: $0.1) })
	}
}

extension StyleUpdateSummaryGenerator {
	struct Heading {
		let name: String
	}
}

extension StyleUpdateSummaryGenerator.Heading: CodeTemplateReplacable {
	var declarationName: String {
		return "headingDeclaration"
	}
	
	var replacementDictionary: [String : String] {
		return ["headingName": name]
	}
}
