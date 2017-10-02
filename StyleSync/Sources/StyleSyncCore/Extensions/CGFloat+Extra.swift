//
//  CGFloat+Extra.swift
//  StyleSync
//
//  Created by Dylan Lewis on 02/10/2017.
//

import Foundation

extension CGFloat {
	var roundedToTwoDecimalPlaces: CGFloat {
		return rounded(toPlaces: 2)
	}
	
	func rounded(toPlaces places: Int) -> CGFloat {
		let divisor = pow(10.0, CGFloat(places))
		return (self * divisor).rounded() / divisor
	}
}
