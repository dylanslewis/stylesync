//
//  GitHubLink.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 25/10/2017.
//

import Foundation

enum GitHubLink {
	private static let baseURL = URL(string: "https://github.com/dylanlewis/stylesync")!
	
	static let createIssue = baseURL.appendingPathComponent("issues/new")
	static let templatesDirectory = baseURL.appendingPathComponent("issues/new") // FIXME: Use real URL
	static let templateReadme = baseURL.appendingPathComponent("issues/new") // FIXME: Use real URL
}
