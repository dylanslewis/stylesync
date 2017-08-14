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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Text Styles"
		navigationController?.navigationBar.prefersLargeTitles = true
	}
}

extension TextStylesViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return TextStyle.allGeneratedStylesAndCodeNameAndName.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "TextStyleCell") else {
			fatalError()
		}
		let (textStyle, codeName, name) = TextStyle.allGeneratedStylesAndCodeNameAndName[indexPath.row]
		cell.textLabel?.attributedText = NSAttributedString(string: name, textStyle: textStyle)
		return cell
	}
}

