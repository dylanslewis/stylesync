//
//  GitHubLink.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 25/10/2017.
//

import Foundation

enum GitHubLink {
	private static let baseURL = URL(string: "https://github.com/dylanslewis/stylesync")!
	
	static let createIssue = baseURL.appendingPathComponent("issues/new")
	static let templatesDirectory = baseURL.appendingPathComponent("tree/master/Sources/StyleSyncCore/Templates")
	static let templateReadme = baseURL.appendingPathComponent("tree/master/Sources/StyleSyncCore/Templates/README.md")
}
