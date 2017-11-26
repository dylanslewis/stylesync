//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

struct GitHubPullRequestManager {
	// MARK: - Stored properties
	
	private let username: String
	private let repositoryName: String
	private let personalAccessToken: String
	
	// MARK: - Computed properties
	
	private var pullRequestURL: URL? {
		return URL(string: "https://api.github.com/repos/\(username)/\(repositoryName)/pulls")
	}
	
	// MARK: - Initializer
	
	init(
		username: String,
		repositoryName: String,
		personalAccessToken: String
	) {
		self.username = username
		self.repositoryName = repositoryName
		self.personalAccessToken = personalAccessToken
	}
	
	// MARK: - Actions
	
	func submit(pullRequest: GitHub.PullRequest) throws {
		let encoder = JSONEncoder()
		let pullRequestData = try encoder.encode(pullRequest)
		
		let usernameAndPersonalAccessToken = "\(username):\(personalAccessToken)"
		guard let loginData = usernameAndPersonalAccessToken.data(using: .utf8) else {
			throw Error.failedToCreateLoginData
		}
		let base64LoginString = loginData.base64EncodedString()
		
		guard let pullRequestURL = pullRequestURL else {
			throw Error.cannotCreatePullRequestURL
		}
		
		let request = URLRequest(url: pullRequestURL, httpMethod: .post, httpBody: pullRequestData)
		
		let semaphore = DispatchSemaphore(value: 0)
		make(urlRequest: request, base64EncodedCredential: base64LoginString) {
			semaphore.signal()
		}
		semaphore.wait()
	}
	
	private func make(urlRequest: URLRequest, base64EncodedCredential: String, withCompletion completion: @escaping () -> Void) {
		let config = URLSessionConfiguration.default
		let authString = "Basic \(base64EncodedCredential)"
		config.httpAdditionalHeaders = ["Authorization" : authString]
		let session = URLSession(configuration: config)
		
		let task = session.dataTask(with: urlRequest) { (data, urlResponse, error) in
			if let error = error {
				ErrorManager.log(fatalError: error, context: .gitHub)
			}
			completion()
		}
		task.resume()
	}
}

extension GitHubPullRequestManager {
	enum Error: Swift.Error, CustomStringConvertible {
		case cannotCreatePullRequestURL
		case failedToCreateLoginData
		
		/// A string describing the error.
		public var description: String {
			switch self {
			case .failedToCreateLoginData, .cannotCreatePullRequestURL:
				return """
				Failed to extract username and GitHub personal access token. Please make sure you are running Style Sync in a git repository and that your GitHub Personal Access Token is correct in `stylesyncConfig.json`.
				
				You can view your personal access tokens at \(GitHubLink.personalAccessTokens).
				"""
			}
		}
	}
}
