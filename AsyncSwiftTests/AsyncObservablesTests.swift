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

	@AsyncObservable(DispatchQueue.main) var value: Result<Int?, Error>
    func testCreation() {
		value = .success(17)
		print("!!! \($value)")
	}

}
