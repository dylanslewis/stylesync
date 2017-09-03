//
//  PullRequestBody.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 03/09/2017.
//

import Foundation

struct PullRequestBody {
	let body: String

	init(
		oldColorStyles: [ColorStyle],
		newColorStyles: [ColorStyle],
		oldTextStyles: [TextStyle],
		newTextStyles: [TextStyle],
		updatedStylesTableTemplate: Template
	) throws {
		let updatedColorStyles = PullRequestBody.updatedStyles(oldStyles: oldColorStyles, newStyles: newColorStyles)
		let updatedTextStyles = PullRequestBody.updatedStyles(oldStyles: oldTextStyles, newStyles: newTextStyles)
		let allUpdatedStyles = updatedColorStyles + updatedTextStyles
		
		let updatedStylesTableCodeGenerator = try CodeGenerator(template: updatedStylesTableTemplate)
		let allUpdatedStylesTableCode = allUpdatedStyles.map({ return PullRequestBody.tableAndHeading(for: $0, generator: updatedStylesTableCodeGenerator) })
		
		self.body = allUpdatedStylesTableCode.joined(separator: "\n")
	}
	
	private static func tableAndHeading(for updatedStyle: UpdatedStyle, generator: CodeGenerator) -> String {
		let heading = "### `\(updatedStyle.styleName)`\n"
		return heading + generator.generatedCode(for: [updatedStyle.updatedAttributes]) + "\n"
	}
	
	private static func updatedStyles<S: Style & CodeTemplateReplacable>(oldStyles: [S], newStyles: [S]) -> [UpdatedStyle] {
		return newStyles.flatMap { newStyle in
			guard let oldStyle = oldStyles
				.first(where: { $0.identifier == newStyle.identifier }) else {
					return nil
			}
			return UpdatedStyle(oldStyle: oldStyle, newStyle: newStyle)
		}
	}
}
