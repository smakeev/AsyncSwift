//
//  StreamTests.swift
//  AsyncSwiftTests
//
//  Created by Sergey Makeev on 04.12.2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import Foundation
import XCTest

@testable import AsyncSwift

class StreamTests: XCTestCase {

	weak var streamToTestDealloc: AStream<Int>? = nil

	override func tearDown() {
		XCTAssert(streamToTestDealloc == nil)
	}

	func testStreamCreate() {
		let stream = AStream<Int>()
		streamToTestDealloc = stream
	}

	func testStreamCreateUsingAsyncStreamFunction() {
		let stream: AStream<Int> = asyncStream {
				do {
					try $0(5)
				} catch {
				
				}
			}
		streamToTestDealloc = stream
	}
	
	func testAutoStop() {
		let stream: AStream<Int> = asyncStream {
			do {
				try $0(5)
			} catch {
			
			}
		}
		streamToTestDealloc = stream
		stream.start(autoStop: true)
		sleep(1)
	}
	
	func testStop() {
		let stream: AStream<Int> = asyncStream {
			do {
				try $0(5)
			} catch {
			
			}
		}
		streamToTestDealloc = stream
		stream.start()
		stream.stop()
	}
	
	func testProviding() {
		let stream = AStream<Int>()
		streamToTestDealloc = stream
		stream.start() //optional call
		
		XCTAssert(stream.lastValue == nil)
		try? stream.provider(1)
		XCTAssert(stream.lastValue == 1)
		try? stream.provider(2)
		XCTAssert(stream.lastValue == 2)

		stream.stop()
		try? stream.provider(3)
		XCTAssert(stream.lastValue == 2)
	}
	
	func testStatesWithStart() {
		let stream = AStream<Int>()
		streamToTestDealloc = stream
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == false)
		stream.start()
		try? stream.provider(1)
		XCTAssert(stream.isActive == true)
		XCTAssert(stream.isClosed == false)

		stream.stop()
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == true)

	}
	
	func testStatesWithStartAndAutoStop() {
		let stream = AStream<Int>()
		streamToTestDealloc = stream
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == false)

		stream.start(autoStop: true) //due to no body it will be closed soon
		sleep(1)
		try? stream.provider(1)
		sleep(1)
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == true)
	}
	
	func testStatesWithoutStart() {
		let stream = AStream<Int>()
		streamToTestDealloc = stream
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == false)

		try? stream.provider(1)
		XCTAssert(stream.isActive == true)
		XCTAssert(stream.isClosed == false)

		stream.stop()
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == true)
	}
	
	func testToArray() {
		let stream = AStream<Int>()
		streamToTestDealloc = stream
		stream.arraySize = 5
		try? stream.provider(0)
		try? stream.provider(1)
		try? stream.provider(2)
		try? stream.provider(3)
		try? stream.provider(4)
		XCTAssert([0, 1, 2, 3, 4] == stream.toArray())
		try? stream.provider(5)
		XCTAssert([1, 2, 3, 4, 5] == stream.toArray())
		try? stream.provider(6)
		XCTAssert([2, 3, 4, 5, 6] == stream.toArray())
		//we can not call stop due to we did not use body.
	}
	
	func testToArrayFromAsyncStream() {
		let stream: AStream<Int> = asyncStream {
			do {
				for i in 0..<5 {
					try $0(i)
				}
			}
		}
		streamToTestDealloc = stream
		stream.arraySize = 5
		stream.start()
		sleep(5)
		XCTAssert([0, 1, 2, 3, 4] == stream.toArray())
		stream.stop()
	}
	
	func testMutableStream() {
		let stream = MAStream<Int>()
		streamToTestDealloc = stream
		stream.arraySize = 100
		
		stream.addBody {
			sleep(1)
			try? $0(0)
		}

		stream.addBody {
			sleep(1)
			try? $0(1)
		}

		stream.addBody {
			sleep(1)
			try? $0(2)
		}

		stream.addBody {
			sleep(1)
			try? $0(3)
		}
		
		stream.start(autoStop: true)
		while !stream.isClosed {
			print("Waiting to stream stop")
		}
		sleep(1)
		stream.reopen()
		sleep(1)
		stream.reopen()
		sleep(1)
		stream.reopen()
		sleep(1)
		stream.reopen()
		sleep(1)
		stream.reopen()
		
		sleep(5)
		XCTAssert([0, 1, 2, 3] == stream.toArray())
		XCTAssert(stream.hasBeenReopened)
		XCTAssert(stream.isClosed)
		XCTAssert(!stream.isActive)
	}
	
	func testMultyStart() {
		let stream = MAStream<Int>()
		streamToTestDealloc = stream
		var count = 0
		stream.addBody {
			sleep(1)
			try? $0(0)
			count += 1
		}
		XCTAssert(count == 0)
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == false)
		stream.start(autoStop: true)
		
		XCTAssert(stream.isActive == true)
		XCTAssert(stream.isClosed == false)
		sleep(2)
		XCTAssert(count == 1)
		stream.start()
		
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == true)
		XCTAssert(count == 1)

		stream.start()
		
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == true)
		XCTAssert(count == 1)
		stream.start()
		
		XCTAssert(stream.isActive == false)
		XCTAssert(stream.isClosed == true)
		XCTAssert(count == 1)
		stream.start()
		XCTAssert(count == 1)
	}
	
	func testListeners() {
		//@TODO:
	}
}
