//
//  Style.swift
//  StyleSync
//
//  Created by Dylan Lewis on 20/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

protocol Style {
	var name: String { get }
	var identifier: String { get }
	var isDeprecated: Bool { get }
	var deprecated: Style { get }
}
