//
//  CodeTemplateReplaceable.swift
//  SketchStyleExporter
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import Foundation

protocol CodeTemplateReplacable {
	static var declarationName: String { get }
	var replacementDictionary: [String: String] { get }
}
