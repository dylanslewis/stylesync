//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

struct GitHub {
	struct PullRequest: Codable {
		let title: String
		let body: String
		let head: String
		let base: String
	}
}
