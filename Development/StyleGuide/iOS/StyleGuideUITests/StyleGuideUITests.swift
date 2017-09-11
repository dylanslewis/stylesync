//
//  StyleGuideUITests.swift
//  StyleGuideUITests
//
//  Created by Dylan Lewis on 11/09/2017.
//  Copyright © 2017 Dylan Lewis. All rights reserved.
//

import XCTest

class StyleGuideUITests: XCTestCase {
	private var screen: XCUIScreen {
		return .main
	}
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
		XCTContext.runActivity(named: "Take screenshots") { activity in
			tabBar.buttons.allElementsBoundByIndex.forEach({ tabButton in
				tabButton.tap()
				let screenshot = self.screen.screenshot()
				let attachment = XCTAttachment(screenshot: screenshot)
				attachment.lifetime = .keepAlways
				activity.add(attachment)
			})
		}
    }
}
