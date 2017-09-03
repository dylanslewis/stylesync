//
//  GitHubPullRequestManager.swift
//  StyleSyncPackageDescription
//
//  Created by Dylan Lewis on 03/09/2017.
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
		let loginData = usernameAndPersonalAccessToken.data(using: .utf8)!
		let base64LoginString = loginData.base64EncodedString()
		
		guard let pullRequestURL = pullRequestURL else {
			throw Error.cannotCreatePullRequestURL
		}
		
		let request = URLRequest(url: pullRequestURL, httpMethod: .post, httpBody: pullRequestData)
		
		let semaphore = DispatchSemaphore(value: 0)
		
		make(urlRequest: request, base64EncodedCredential: base64LoginString) {
			print("Done here")
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
				print(error)
			}
			
			if let data = data, let dataString = String(data: data, encoding: String.Encoding.utf8) {
				print(dataString)
			}
			
			completion()
		}
		task.resume()
	}
}

extension GitHubPullRequestManager {
	enum Error: Swift.Error {
		case cannotCreatePullRequestURL
	}
}
