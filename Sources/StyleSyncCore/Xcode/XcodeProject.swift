//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation
import Files
import ShellOut

struct XcodeScheme: Codable {
	let version: String
}

enum iOSDeviceType: String {
	case iPhone7Plus = "iPhone 7 Plus"
}

struct XcodeProject {
	let projectDirectory: Folder
	
	func run(test: Test, scheme: String, device: iOSDeviceType = .iPhone7Plus, os: Version = .init(major: 11, minor: 0)) throws {
		try shellOut(to: .xcodeRunTest(test: test, scheme: scheme, device: device, os: os), at: projectDirectory.path)
	}
}

extension XcodeProject {
	struct Test {
		let testSuite: String
		let testCase: String
		let testName: String
	}
}

private extension ShellOutCommand {
	static func xcodeRunTest(test: XcodeProject.Test, scheme: String, device: iOSDeviceType, os: Version) -> ShellOutCommand {
		var command = "xcodebuild"
		command.append(parameter: "-scheme")
		command.append(parameter: scheme)
		command.append(parameter: "test")
		command.append(parameter: "-only-testing:\(test.testSuite)/\(test.testCase)/\(test.testName)")
		command.append(parameter: "-destination")
		command.append(parameter: "'platform=iOS Simulator,name=\(device.rawValue),OS=\(os.stringRepresentation)'")
		command.append(parameter: "-quiet")
		return ShellOutCommand(string: command)
	}
}
