//
//  ShellOutCommand+Extra.swift
//  StyleSyncCore
//
//  Created by Dylan Lewis on 11/09/2017.
//

import ShellOut

extension ShellOutCommand {
	static func changeDirectory(directory: String) -> ShellOutCommand {
		var command = "cd"
		command.append(argument: directory)
		return ShellOutCommand(string: command)
	}
}
