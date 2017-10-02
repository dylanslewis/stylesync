//
//  ShellOutCommand+Extra.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 11/09/2017.
//

import ShellOut

extension ShellOutCommand {
	static func makeDirectory(directory: String) -> ShellOutCommand {
		var command = "mkdir"
		command.append(argument: directory)
		print(command)
		return ShellOutCommand(string: command)
	}
	
	static func removeDirectory(directory: String) -> ShellOutCommand {
		var command = "rm -rf"
		command.append(argument: directory)
		return ShellOutCommand(string: command)
	}
	
	static func changeDirectory(directory: String) -> ShellOutCommand {
		var command = "cd"
		command.append(argument: directory)
		return ShellOutCommand(string: command)
	}
}
