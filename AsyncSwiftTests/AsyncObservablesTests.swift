//
//  AsyncObservablesTests.swift
//  AsyncSwiftTests
//
//  Created by Sergey Makeev on 03.01.2020.
//  Copyright © 2020 SOME projects. All rights reserved.
//

import XCTest

class AsyncObservablesTests: XCTestCase {
	
	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	@AsyncObservable(DispatchQueue.main) var value = 8
	func testCreation() {
		XCTAssert(value == 8)
		value = 17
		XCTAssert(value == 17)
	}
	
	func testObservers(){
		var observerCalled = false
		$value.addObserver(self) { newValue in
			XCTAssert(newValue == 5)
			observerCalled = true
		}
		XCTAssert(observerCalled == false)
		value = 5
		XCTAssert(value == 5)
		XCTAssert(observerCalled == true)
		observerCalled = false
		$value.removeObserver(self)
		value = 6
		XCTAssert(value == 6)
		XCTAssert(observerCalled == false)
	}
	
}
