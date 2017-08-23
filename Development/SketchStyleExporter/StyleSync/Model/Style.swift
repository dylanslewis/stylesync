//
//  Style.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 20/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

protocol Style {
	var name: String { get }
	var identifier: String { get }
}

extension Style {
	var codeName: String {
		return name.camelcased
	}
}
