//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import Foundation

public extension CGFloat {
	var roundedToTwoDecimalPlaces: CGFloat {
		return rounded(toPlaces: 2)
	}
	
	public func rounded(toPlaces places: Int) -> CGFloat {
		let divisor = pow(10.0, CGFloat(places))
		return (self * divisor).rounded() / divisor
	}
}
