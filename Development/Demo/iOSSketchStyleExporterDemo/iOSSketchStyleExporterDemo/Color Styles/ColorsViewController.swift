//
//  ColorsViewController.swift
//  iOSSketchStyleExporterDemo
//
//  Created by Dylan Lewis on 13/08/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import UIKit

class ColorsViewController: UIViewController {
	@IBOutlet var tableView: UITableView! {
		didSet {
			tableView.estimatedRowHeight = 100
			tableView.rowHeight = UITableViewAutomaticDimension
		}
	}
	
	fileprivate let nameAndCodeNameAndColorStyle: [(String, String, UIColor)] = [
		("Sample Black", "sampleBlack", .sampleBlack),
		("Sample Green", "sampleGreen", .sampleGreen),
		("Sample Yellow", "sampleYellow", .sampleYellow),
		("Sample Orange", "sampleOrange", .sampleOrange),
		("Sample Red", "sampleRed", .sampleRed)
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Colours"
		navigationController?.navigationBar.prefersLargeTitles = true
	}
}


extension ColorsViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return nameAndCodeNameAndColorStyle.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ColorStyleCell") as? ColorTableViewCell else {
			fatalError()
		}
		let (name, codeName, color) = nameAndCodeNameAndColorStyle[indexPath.row]
		guard let viewData = ColorTableViewCell.ViewData(name: name, codeName: codeName, color: color) else {
			fatalError()
		}
		cell.configure(with: viewData, textStyle: .sampleSectionHeader)
		return cell
	}
}
