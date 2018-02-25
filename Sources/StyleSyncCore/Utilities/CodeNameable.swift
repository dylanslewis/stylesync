//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

protocol CodeNameable {
	var name: String { get }
}

extension CodeNameable {
	var codeName: String {
		return name.camelcased
	}
}
