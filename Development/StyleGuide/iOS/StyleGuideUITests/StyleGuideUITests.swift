//
//  StyleGuideUITests.swift
//  StyleGuideUITests
//
//  Created by Dylan Lewis on 11/09/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import XCTest

class StyleGuideUITests: XCTestCase {
	private let screen: XCUIScreen = .main
	private var app: XCUIApplication {
		return .init()
	}
	private var tabBar: XCUIElement {
		return app.tabBars.firstMatch
	}
	
	override func setUp() {
		super.setUp()
		app.launch()
	}
	
    func testSpider() {
		tabBar.buttons.allElementsBoundByIndex.forEach({ tabButton in
			tabButton.tap()
			screen.screenshot()
		})
    }
}
