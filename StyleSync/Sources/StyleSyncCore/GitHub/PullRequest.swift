//
//  GitHub.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 03/09/2017.
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
