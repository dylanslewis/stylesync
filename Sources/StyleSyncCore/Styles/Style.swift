//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

protocol Style {
	var name: String { get }
	var identifier: String { get }
	var isDeprecated: Bool { get }
	var deprecated: Style { get }
}
