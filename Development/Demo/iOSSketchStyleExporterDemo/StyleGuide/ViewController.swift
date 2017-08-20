//
//  ViewController.swift
//  iOSSketchStyleExporterDemo
//
//  Created by Dylan Lewis on 12/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import UIKit

class TextStylesViewController: UIViewController {
	@IBOutlet var tableView: UITableView! {
		didSet {
			tableView.estimatedRowHeight = 100
			tableView.rowHeight = UITableViewAutomaticDimension
		}
	}
	
	fileprivate let nameAndTextStyle: [(String, TextStyle)] = [
		("Sample Heading", .sampleHeading),
		("Sample Title", .sampleTitle),
		("Sample Body", .sampleBody)
	]
	
	fileprivate let nameAndColorStyle: [(String, UIColor)] = [
		("Sample Black", .sampleBlack),
		("Sample Green", .sampleGreen),
		("Sample Yellow", .sampleYellow),
		("Sample Orange", .sampleOrange),
		("Sample Red", .sampleRed)
	]
}

extension TextStylesViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return nameAndTextStyle.count + nameAndColorStyle.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row < nameAndTextStyle.count {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "TextStyleCell") else {
				fatalError()
			}
			let (name, textStyle) = nameAndTextStyle[indexPath.row]
			cell.textLabel?.attributedText = NSAttributedString(string: name, textStyle: textStyle)
			return cell
		} else {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "ColorStyleCell") as? ColorTableViewCell else {
				fatalError()
			}
			let index = indexPath.row - nameAndTextStyle.count
			let (name, color) = nameAndColorStyle[index]
			guard let viewData = ColorTableViewCell.ViewData(name: name, color: color) else {
				fatalError()
			}
			cell.configure(with: viewData, textStyle: .sampleBody)
			return cell
		}
	}
}

