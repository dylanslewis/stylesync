//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

enum GitHubLink {
	private static let baseURL = URL(string: "https://github.com/dylanslewis/stylesync")!
	
	static let createIssue = baseURL.appendingPathComponent("issues/new")
	static let templatesDirectory = baseURL.appendingPathComponent("tree/master/Sources/StyleSyncCore/Templates")
	static let templateReadme = baseURL.appendingPathComponent("tree/master/Sources/StyleSyncCore/Templates/README.md")
	static let personalAccessTokens = URL(string: "https://github.com/settings/tokens")!
}
