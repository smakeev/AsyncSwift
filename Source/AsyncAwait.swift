//
//  AsyncAwait.swift
//  SomeAsyncAwait
//
//  Created by Sergey Makeev on 29.10.2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import Foundation

public enum AFutureErrors: Error {
	case FutureError
}

public func async<Type>(_ block: @escaping () throws -> Type) -> AsyncAwaitFuture<Type> {
	let future = AsyncAwaitFuture<Type>()

	DispatchQueue.global().async {
		do {
			future.result = try block()
		}
		catch {
			future.error = error
		}
	}
	return future
}
		

public func asyncStream<Type>(_ block: @escaping ((Type) throws -> Void) throws -> Void) -> AsyncStream<Type> {
	let stream = MutableAsyncStream<Type>()
	stream.addBody(block)
	return stream
}



public func await<Result>(_ future: AsyncAwaitFuture<Result>) throws -> Result? {
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<Result>(_ function: @escaping () -> Result) throws -> Result? {
	let future = async {
		return function()
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<Type, Result>(_ p1: Type, _ function: @escaping (Type) -> Result) throws -> Result? {
	let future = async {
		return function(p1)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<Type, Type1, Result>(_ p1: Type, _ p2: Type1, _ function: @escaping (Type, Type1) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<T, T1, T2, Result>(_ p1: T, _ p2: T1, _ p3: T2, _ function: @escaping (T, T1, T2) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<T1, T2, T3, T4, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ function: @escaping (T1, T2, T3, T4) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3, p4)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<T1, T2, T3, T4, T5, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ function: @escaping (T1, T2, T3, T4, T5) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3, p4, p5)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ function: @escaping (T1, T2, T3, T4, T5, T6) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3, p4, p5, p6)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, T7, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ function: @escaping (T1, T2, T3, T4, T5, T6, T7) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3, p4, p5, p6, p7)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, T7, T8, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ p8: T8, _ function: @escaping (T1, T2, T3, T4, T5, T6, T7, T8) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3, p4, p5, p6, p7, p8)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}

public func await<T1, T2, T3, T4, T5, T6, T7, T8, T9, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ p8: T8, _ p9: T9 , _ function: @escaping (T1, T2, T3, T4, T5, T6, T7, T8, T9) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3, p4, p5, p6, p7, p8, p9)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}


public func await<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, Result>(_ p1: T1, _ p2: T2, _ p3: T3, _ p4: T4, _ p5: T5, _ p6: T6, _ p7: T7, _ p8: T8, _ p9: T9, _ p10: T10 , _ function: @escaping (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) -> Result) throws -> Result? {
	let future = async {
		return function(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
	}
	waitForFutures([future])
	if future.hasError {
		throw AFutureErrors.FutureError
	}
	return future.result
}
