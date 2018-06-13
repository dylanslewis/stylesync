//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

struct StyleParser<S: Style> {
	var newStyles: [S]
	
	func deprecatedStyles(usingPreviouslyExportedStyles previouslyExportedStyles: [S]) -> [S] {
		return previouslyExportedStyles
			.filter { style -> Bool in
				return newStyles.contains(where: { $0.identifier == style.identifier }) == false
			}
			.map({ $0.deprecated })
			.compactMap({ $0 as? S })
	}
	
	func getCurrentAndMigratedStyles(usingPreviouslyExportedStyles previouslyExportedStyles: [S]) -> [(currentStyle: S, migratedStyle: S)] {
		return previouslyExportedStyles
			.compactMap { style -> (S, S)? in
				guard
					let migratedStyle = newStyles
						.first(where: { $0.identifier == style.identifier && $0.name != style.name })
				else {
					return nil
				}
				return (style, migratedStyle)
			}
	}
}
