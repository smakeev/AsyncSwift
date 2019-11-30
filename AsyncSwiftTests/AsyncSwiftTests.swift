//
//  AsyncSwiftTests.swift
//  AsyncSwiftTests
//
//  Created by Sergey Makeev on 16.11.2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import XCTest
@testable import AsyncSwift

class AsyncSwiftTests: XCTestCase {
	override func setUp() {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func f0() -> AFuture<Int> {
		return async {
			sleep(2)
			return 1
		}
	}

	func f1(_ a: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return a
		}
	}

	func f2(f1: Int, f2: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2
		}
	}

	func f3(f1: Int, f2: Int, f3: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3
		}
	}

	func f4(f1: Int, f2: Int, f3: Int, f4: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3 + f4
		}
	}

	func f5(f1: Int, f2: Int, f3: Int, f4: Int, f5: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3 + f4 + f5
		}
	}

	func f6(f1: Int, f2: Int, f3: Int, f4: Int, f5: Int, f6: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3 + f4 + f5 + f6
		}
	}

	func f7(f1: Int, f2: Int, f3: Int, f4: Int, f5: Int, f6: Int, f7: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3 + f4 + f5 + f6 + f7
		}
	}

	func f8(f1: Int, f2: Int, f3: Int, f4: Int, f5: Int, f6: Int, f7: Int, f8: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8
		}
	}

	func f9(f1: Int, f2: Int, f3: Int, f4: Int, f5: Int, f6: Int, f7: Int, f8: Int, f9: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9
		}
	}

	func f10(f1: Int, f2: Int, f3: Int, f4: Int, f5: Int, f6: Int, f7: Int, f8: Int, f9: Int, f10: Int) -> AFuture<Int> {
		return async {
			sleep(2)
			return f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10
		}
	}

	func findEntryPoint() -> AFuture<Tester> {
		return async {
			sleep(2)
			return Tester()
		}
	}

	func runFromEnryPoint(_ tester: Tester) -> AFuture<Tester1> {
		return async {
			sleep(2)
			return Tester1(with: tester)
		}
	}

	func finishChain(_ tester: Tester1) -> AFuture<Void> {
		return async {
			sleep(2)
			let newTester = Tester2(with: tester)
			XCTAssert(newTester.current == 3)
		}
	}

	func finishChainWithOptinalParameter(_ tester: Tester1?) -> AFuture<Void> {
	return async {
			sleep(2)
			guard let validTEster = tester else { return }
			let newTester = Tester2(with: validTEster)
			XCTAssert(newTester.current == 3)
		}
	}

	class Tester {
		var current = 1
	}

	class Tester1 {

		var current = 1

		init(with tester: Tester) {
			current += tester.current
		}
	}

	class Tester2 {

		var current = 1

		init(with tester: Tester1) {
			current += tester.current
		}
	}

	func testAwaitVariant() {
		let future: AFuture<Void> = async {
			let entryPoint = await(self.findEntryPoint)
			let midlePoint = await(entryPoint!, self.runFromEnryPoint)
			return await(midlePoint, self.finishChainWithOptinalParameter)!
		}

		var resolvedCalled = false
		future.onResolved { _ in
			resolvedCalled = true
		}

		sleep(7)
		XCTAssert(future.isResolved)
		XCTAssert(resolvedCalled)
	}


	func testFuturesChainWithSimpleThen() {
		let future = findEntryPoint().then(Tester1.self) { entryPoint in
			guard let validEntryPoint = entryPoint else { fatalError() /*to test exceptions*/}
			return self.runFromEnryPoint(validEntryPoint)
		}.then(Void.self, finishChainWithOptinalParameter)

		var resolvedCalled = false
		future.onResolved { _ in
			resolvedCalled = true
		}

		sleep(7)
		XCTAssert(future.isResolved)
		XCTAssert(resolvedCalled)

	}

	func testFuturesChain() {
		let future = findEntryPoint().then(Tester1.self) { entryPoint in
			guard let validEntryPoint = entryPoint else { fatalError() /*to test exceptions*/}
			return self.runFromEnryPoint(validEntryPoint)
		}.then(Void.self) { middlePoint in
			guard let validMiddlePoint = middlePoint else { fatalError() /*to test exceptions*/}
			return self.finishChain(validMiddlePoint)
		}

		var resolvedCalled = false
		future.onResolved { _ in
			resolvedCalled = true
		}

		sleep(7)
		XCTAssert(future.isResolved)
		XCTAssert(resolvedCalled)
	}

	func testFuture() {
		let future:AFuture<Tester1> = findEntryPoint().then { entryPoint in
			guard let validEntryPoint = entryPoint else { fatalError() /*to test exceptions*/}
			return self.runFromEnryPoint(validEntryPoint)
		}

		future.onResolved { tester1 in
			XCTAssert(tester1!.current == 2)
		}

		sleep(5)
		XCTAssert(future.isResolved)
		XCTAssert(future.result!.current == 2)
	}


	func testExample() {
		let a: AFuture<Int> = async {
			let r1  = await(self.f0)
			let r2  = await(r1!, self.f1)
			let r3  = await(r1!, r2!, self.f2)
			let r4  = await(r1!, r2!, r3!, self.f3)
			let r5  = await(r1!, r2!, r3!, r4!, self.f4)
			let r6  = await(r1!, r2!, r3!, r4!, r5!, self.f5)
			let r7  = await(r1!, r2!, r3!, r4!, r5!, r6!, self.f6)
			let r8  = await(r1!, r2!, r3!, r4!, r5!, r6!, r7!, self.f7)
			let r9  = await(r1!, r2!, r3!, r4!, r5!, r6!, r7!, r8!, self.f8)
			let r10 = await(r1!, r2!, r3!, r4!, r5!, r6!, r7!, r8!, r9!, self.f9)
			let r11 = await(r1!, r2!, r3!, r4!, r5!, r6!, r7!, r8!, r9!, r10!, self.f10)

			return r11!
		}

		a.onResolved {
			XCTAssert($0 == 512)
		}

		sleep(30)
		XCTAssert(a.isResolved)
	}

	var delayFutureResolved: Bool = false
	func testDelay() {
		let future = SomeFuture.delay(3)
		future.onResolved { _ in
			self.delayFutureResolved = true
		}

		sleep(4)
		print("aga")
		XCTAssert(future.isResolved)
		XCTAssert(delayFutureResolved)
	}

	var awaitFutureResolved: Bool = false
	func delayFunc() -> AFuture<Void> {
		let future = SomeFuture.delay(10)
		future.onResolved{ _ in
			self.awaitFutureResolved = true
		}
		return future
	}

	func testAwaitDelay() {
		await(delayFunc)
		XCTAssert(awaitFutureResolved)
	}

	var awaitedFutureResolved: Bool = false
	func testAwaitFutureDelay() {
		await(SomeFuture.delay(3).onResolved { _ in
			self.awaitedFutureResolved = true
		})

		XCTAssert(awaitedFutureResolved)
	}
	
	func testWaitFutures() {
		let future1 = SomeFuture.delay(3)
		let future2 = SomeFuture.delay(5)
		let future3: AFuture<Int> = async {
			for _ in 1...1000000 {
				//doNothing
			}
			return 10
		}
		await(SomeFuture.wait([future1, future2, future3]))
		XCTAssert(future1.resolved)
		XCTAssert(future2.resolved)
		XCTAssert(future3.resolved)
	}

	

}
