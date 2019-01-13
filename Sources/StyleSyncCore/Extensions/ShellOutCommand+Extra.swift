//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import ShellOut

extension ShellOutCommand {
	static func makeDirectory(directory: String) -> ShellOutCommand {
		var command = "mkdir"
		command.append(argument: directory.wrappedInQuotes)
		return ShellOutCommand(string: command)
	}
	
	static func removeDirectory(directory: String) -> ShellOutCommand {
		var command = "rm -rf"
		command.append(argument: directory.wrappedInQuotes)
		return ShellOutCommand(string: command)
	}
	
	static func changeDirectory(directory: String) -> ShellOutCommand {
		var command = "cd"
		command.append(argument: directory.wrappedInQuotes)
		return ShellOutCommand(string: command)
	}
}
