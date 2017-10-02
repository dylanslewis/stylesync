//
//  URLRequest+Extra.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 03/09/2017.
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
