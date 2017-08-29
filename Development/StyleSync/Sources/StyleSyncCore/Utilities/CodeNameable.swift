//
//  CodeNameable.swift
//  StyleSync
//
//  Created by Dylan Lewis on 14/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

protocol CodeNameable {
	var name: String { get }
}

extension CodeNameable {
	var codeName: String {
		return name.camelcased
	}
}
