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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Colours"
		navigationController?.navigationBar.prefersLargeTitles = true
	}
}

extension ColorsViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return UIColor.allGeneratedStylesAndCodeNameAndName.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ColorStyleCell") as? ColorTableViewCell else {
			fatalError()
		}
		let (color, codeName, name) = UIColor.allGeneratedStylesAndCodeNameAndName[indexPath.row]
		guard let viewData = ColorTableViewCell.ViewData(name: name, codeName: codeName, color: color) else {
			fatalError()
		}
		cell.configure(with: viewData, textStyle: .sampleSectionHeader)
		return cell
	}
}
