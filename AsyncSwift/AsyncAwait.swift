//
//  AsyncAwait.swift
//  SomeAsyncAwait
//
//  Created by Sergey Makeev on 29.10.2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import Foundation

public func async<Type>(_ block: @escaping () -> Type) -> AsyncAwaitFuture<Type> {
	var future = AsyncAwaitFuture<Type>()
	defer {
		DispatchQueue.global().async {
			future.result = block()
		}
	}
	
	return future
}

public func await<Result>(_ future: AsyncAwaitFuture<Result>) -> Result? {
	waitForFutures([future])
	return future.result
}

public func await<Result>(_ function: () -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function()
	waitForFutures([future])
	return future.result
}

public func await<Type, Result>(_ p1: Type, _ function: (Type) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1)
	waitForFutures([future])
	return future.result
}

public func await<Type, Type1, Result>(_ p1: Type, _ p2: Type1, _ function: (Type, Type1) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2)
	waitForFutures([future])
	return future.result
}

public func await<T, T1, T2, Result>(_ p1: T, _ p2: T1, _ p3: T2, _ function: (T, T1, T2) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3)
	waitForFutures([future])
	return future.result
}

public func await<T1, T2, T3, T4, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ function: (T1, T2, T3, T4) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3, p4)
	waitForFutures([future])
	return future.result
}

public func await<T1, T2, T3, T4, T5, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ function: (T1, T2, T3, T4, T5) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3, p4, p5)
	waitForFutures([future])
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ function: (T1, T2, T3, T4, T5, T6) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3, p4, p5, p6)
	waitForFutures([future])
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, T7, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ function: (T1, T2, T3, T4, T5, T6, T7) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3, p4, p5, p6, p7)
	waitForFutures([future])
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, T7, T8, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ p8: T8, _ function: (T1, T2, T3, T4, T5, T6, T7, T8) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3, p4, p5, p6, p7, p8)
	waitForFutures([future])
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, T7, T8, T9, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ p8: T8, _ p9: T9 , _ function: (T1, T2, T3, T4, T5, T6, T7, T8, T9) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3, p4, p5, p6, p7, p8, p9)
	waitForFutures([future])
	return future.result
}


public func await<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ p8: T8, _ p9: T9, _ p10: T10 , _ function: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) -> AsyncAwaitFuture<Result>) -> Result? {
	let future = function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
	waitForFutures([future])
	return future.result
}
