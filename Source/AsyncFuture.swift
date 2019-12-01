//
//  AsyncFuture.swift
//  AsyncSwift
//
//  Created by Sergey Makeev on 01.12.2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import Foundation

public typealias AFuture = AsyncAwaitFuture
public typealias SomeFuture = AFuture<Void>

public protocol FutureAlwaysProtocol {
	@discardableResult func always(_ handler: @escaping () -> Void) -> Self
}

internal protocol Resolvable: class {

	var isResolved: Bool { get }
	func resolveWith(_ result: Any?)
	func resolveWithError(_ error: Any?)
	func resolveFromSubFuture(_ result: Any?)
	func resolveFromSubFutureWithError(_ error: Any?)
}

internal func waitForFutures<Type>(_ futures: [AsyncAwaitFuture<Type>], handler: (() -> Void)? = nil) {
	var finished = 0
	var sleeping = true
	let condition = NSCondition()
	for future in futures {
			future.always {
					condition.lock()
					finished += 1
					if finished == futures.count {
						if sleeping {
							condition.signal()
						}
						sleeping = false
					}
					condition.unlock()
			}
	}
	
	while sleeping {
		if sleeping {
			condition.wait()
		}
	}
}

public class AsyncAwaitFuture<Type>: Resolvable, FutureAlwaysProtocol {
	
	func resolveWith(_ result: Any?) {
		fatalError("This is only for subclass")
	}
	
	func resolveWithError(_ error: Any?) {
		fatalError("This is only for subclass")
	}
	
	func resolveFromSubFuture(_ result: Any?) {
		fatalError("This is only for subclass")
	}
	
	func resolveFromSubFutureWithError(_ error: Any?) {
		fatalError("This is only for subclass")
	}
	
	private var queue: DispatchQueue
	init(_ queue: DispatchQueue? = nil) {
		if let validQueue = queue {
			self.queue = validQueue
		} else {
			self.queue = DispatchQueue(label: "default queue")
		}
	}
	
	public static func delay(_ time: TimeInterval) -> AFuture<Void> {
		let future = AFuture<Void>()
		future.queue.asyncAfter(deadline: .now() + time) {
			future.result = nil
		}
		
		return future
	}
	
	public static func wait(_ futures: [FutureAlwaysProtocol]) -> AFuture<Void> {
		let future = AFuture<Void>()
		let count = futures.count
		var current = 0
		for item in futures {
			item.always {
				future.syncQueue.sync {
					current += 1
					if current == count {
						future.queue.async {
							future.result = nil
						}
					}
				}
			}
		}
	
		return future
	}


	var _onError: [((Any?) -> Void)] = Array.init()
	@discardableResult public func onError(_ block: @escaping (Any?) -> Void) -> AsyncAwaitFuture<Type> {
		syncQueue.sync {
			_onError.append(block)
			if resolved {
				doNotifications()
			}
		}
		
		return self
	}
	
	var _onSuccess: [((Type?) -> Void)] = Array.init()
	@discardableResult public func onSuccess(_ block: @escaping (Type?) -> Void) -> AsyncAwaitFuture<Type> {
		syncQueue.sync {
			_onSuccess.append(block)
			if resolved {
				doNotifications()
			}
		}
		
		return self
	}
	
	weak var _superOwner: Resolvable? = nil
	var _dependantFutures: [Resolvable] = [Resolvable]()
	
	private class DependantFuture<Type, PrevType>: AsyncAwaitFuture<Type> {
		var block: (PrevType?) -> AFuture<Type>
		init(_ block: @escaping (PrevType?) -> AFuture<Type>, _ queue: DispatchQueue, _ owner:  AFuture<PrevType>) {
			self.block = block
			self.owner = owner
			super.init(queue)
		}

		var owner: AFuture<PrevType>?

		override func resolveWith(_ result: Any?) {
			var future: AFuture<Type>? = nil
			if let validResult = result as? PrevType {
				future = block(validResult)
			} else {
				future = block(nil)
			}
			future?._dependantFutures.append(contentsOf: self._dependantFutures)
			future?._onSuccess.append(contentsOf: self._onSuccess)
			future?._superOwner = self
			self._dependantFutures = [Resolvable]()
			self._onSuccess = [((Type?) -> Void)]()
			owner = nil
		}
		
		override func resolveWithError(_ error: Any?) {
			self.error = error
			owner = nil
		}
		
		override func resolveFromSubFuture(_ result: Any?) {
			syncQueue.sync {
				if result != nil {
					guard let validResult = result as? Type else { return }
					_result  = validResult
				}
				resolved = true
			}
		}
		
		override func resolveFromSubFutureWithError(_ error: Any?) {
			syncQueue.sync {
				_error   = error
				resolved = true
				hasError = true
			}
		}
	}

	internal init(resolved withResult: Type?) {
		resolved = true
		_result  = withResult
		self.queue = DispatchQueue(label: "default queue")
	}

	public static func resolved() -> AFuture<Type> {
		return AFuture<Type>.init(resolved: nil)
	}
	
	public static func resolved(with providedResult: Type?) -> AFuture<Type> {
		return AFuture<Type>.init(resolved: providedResult)
	}

	public func then<TypeNext>(_ type: TypeNext.Type = TypeNext.self, _ block: @escaping (Type?) -> AFuture<TypeNext>) -> AFuture<TypeNext> {
		let future = DependantFuture<TypeNext, Type>(block, self.queue, self)
		syncQueue.sync {
			_dependantFutures.append(future)
			if resolved {
				doNotifications()
			}
		}
		return future
	}
	
	internal var dependantErrorFutures: [AFuture<Type>] = [AFuture<Type>] ()
	internal var dependantErrorFuturesHandlers: [(Any?) throws -> Type] = [(Any?) throws -> Type]()
	public func catchError(_ block: @escaping (Any?) throws -> Type) -> AFuture<Type> {
		let future = AFuture<Type>(self.queue)
		syncQueue.sync {
			dependantErrorFutures.append(future)
			dependantErrorFuturesHandlers.append(block)
			if resolved {
				doNotifications()
			}
		}
		return future
	}
	
	var alwaysDo: [()->Void] = [()->Void]()
	@discardableResult public func always(_ handler: @escaping () -> Void) -> Self {
		syncQueue.sync {
			alwaysDo.append(handler)
			if resolved {
				doNotifications()
			}
		}
		return self
	}

	private var syncQueue: DispatchQueue = DispatchQueue(label: "AsyncAwaitFutureSyncQueue")
	internal var resolved: Bool = false
	internal var _result: Type? = nil
	
	private func doNotifications() {
	
		if !_hasError {
			for notifBlock in self._onSuccess {
				queue.async {
					notifBlock (self._result)
				}
			}
		} else {
			for notifBlock in self._onError {
				queue.async {
					notifBlock (self._error)
				}
			}
		}
		self._onSuccess.removeAll()
		self._onError.removeAll()
		
		if !_hasError {
			for dependantFuture in self._dependantFutures {
				queue.async {
					dependantFuture.resolveWith(self._result)
				}
			}
		} else {
			for dependantFuture in self._dependantFutures {
				queue.async {
					dependantFuture.resolveWithError(self._error)
				}
		}

		}
		self._dependantFutures.removeAll()
		
		if !_hasError {
			for errorCatcherFuture in dependantErrorFutures {
				errorCatcherFuture.result = _result
			}
		} else {
			var currentIndex = 0
			for errorCatcherFuture in dependantErrorFutures {
				do {
					errorCatcherFuture.result = try dependantErrorFuturesHandlers[currentIndex](_error)
				}
				catch {
					errorCatcherFuture.error = error
				}
				currentIndex += 1
			}
		}
		dependantErrorFuturesHandlers.removeAll()
		dependantErrorFutures.removeAll()
		
		for always in self.alwaysDo {
			queue.async {
				always()
			}
		}
		self.alwaysDo.removeAll()
	}
	
	var _hasError: Bool = false
	public internal(set) var hasError: Bool {
		get {
			syncQueue.sync {
				return _hasError
			}
		}
		
		set {
			syncQueue.sync {
				guard resolved == false else { return }
				_hasError = newValue
			}
		}
	}
	var _error: Any? = nil
	public internal(set) var error: Any? {
		get {
			syncQueue.sync {
				return _error
			}
		}

		set {
			syncQueue.sync {
				guard resolved == false else { return }
				_error = newValue
				_hasError = true
				resolved = true
				doNotifications()
				_superOwner?.resolveFromSubFutureWithError(_error)
			}
		}
	}
	
	public internal (set) var result: Type? {
		get {
			syncQueue.sync {
				_result
			}
		}
		
		set {
			syncQueue.sync {
				guard resolved == false else { return }
				_result = newValue
				resolved = true
				doNotifications()
				_superOwner?.resolveFromSubFuture(_result)
			}
		}
			
	}
	
	public var isResolved: Bool {
		syncQueue.sync { resolved }
	}
}
