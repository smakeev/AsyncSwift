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
	func always(_ handler: @escaping () -> Void)
}

internal protocol Resolvable: class {

	var isResolved: Bool { get }
	func resolveWith(_ result: Any?)
	func resolveFromSubFuture(_ result: Any?)
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
	
	func resolveFromSubFuture(_ result: Any?) {
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

	
	var _onResolved: [((Type?) -> Void)] = Array.init()
	@discardableResult public func onResolved(_ block: @escaping (Type?) -> Void) -> AsyncAwaitFuture<Type> {
		syncQueue.sync {
			_onResolved.append(block)
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
			future?._onResolved.append(contentsOf: self._onResolved)
			future?._superOwner = self
			self._dependantFutures = [Resolvable]()
			self._onResolved = [((Type?) -> Void)]()
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
	
	var alwaysDo: [()->Void] = [()->Void]()
	public func always(_ handler: @escaping () -> Void) {
		syncQueue.sync {
			alwaysDo.append(handler)
			if resolved {
				doNotifications()
			}
		}
	}

	private var syncQueue: DispatchQueue = DispatchQueue(label: "AsyncAwaitFutureSyncQueue")
	internal var resolved: Bool = false
	internal var _result: Type? = nil
	
	private func doNotifications() {
		for notifBlock in self._onResolved {
			queue.async {
				notifBlock (self._result)
			}
		}
		self._onResolved.removeAll()
		
		for dependantFuture in self._dependantFutures {
			queue.async {
				dependantFuture.resolveWith(self._result)
			}
		}
		self._dependantFutures.removeAll()
		
		for always in self.alwaysDo {
			queue.async {
				always()
			}
		}
		self.alwaysDo.removeAll()
	}
	
	public internal (set) var result: Type? {
		get {
			syncQueue.sync {
				_result
			}
		}
		
		set {
			syncQueue.sync {
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
