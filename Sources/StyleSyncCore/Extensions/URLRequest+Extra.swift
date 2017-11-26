//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

enum HTTPMethod: String {
	case post = "POST"
}

extension URLRequest {
	init(url: URL, httpMethod: HTTPMethod, httpBody: Data? = nil) {
		self = URLRequest(url: url)
		self.httpMethod = httpMethod.rawValue
		if let httpBody = httpBody {
			self.httpBody = httpBody
		}
	}
}
