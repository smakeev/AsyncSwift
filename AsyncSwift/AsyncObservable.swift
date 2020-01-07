//
//  AsyncObservable.swift
//  AsyncSwift
//
//  Created by Sergey Makeev on 03.01.2020.
//  Copyright © 2020 SOME projects. All rights reserved.
//

import Foundation

public protocol AsyncObserver {
	associatedtype ResultType
	associatedtype ErrorType: Error
	@discardableResult mutating func addObserver(_ observer: AnyObject, on queue: DispatchQueue, _ handler: @escaping (Result<ResultType?, ErrorType>) -> Void) -> Bool
	@discardableResult mutating func removeObserver(_ observer: AnyObject) -> Bool
}

@propertyWrapper
struct AsyncObservable<T, E: Error>: AsyncObserver {
	
	
	private var queue: DispatchQueue? = nil
	public init(_ queue: DispatchQueue? = nil) {
		self.queue = queue
		self.value = Result.success(nil)
	}

	private var value: Result<T?, E>
	public var wrappedValue: Result<T?, E> {
		get {
			return value
		}
		
		set {
			self.value = newValue
		
			self.syncQueue.sync {
				self.observers = self.observers.filter {
					$0.observer != nil
				}
				for observer in observers {
					observer.queue.async {
						observer.handler(newValue)
					}
				}
			}
		}
	}
	
	public typealias ResultType = T
	public typealias ErrorType  = E
	
	private let syncQueue: DispatchQueue = DispatchQueue(label: "AsyncObserverSyncQueue")
	
	private struct Wrapper {
		var observer: AnyObject? = nil
		var handler: ((Result<T?,E>) -> Void)!
		var queue: DispatchQueue
	}
	
	private var observers = [Wrapper]()
	
	@discardableResult public mutating func addObserver(_ observer: AnyObject, on queue: DispatchQueue, _ handler: @escaping (Result<T?,E>) -> Void) -> Bool {
		return syncQueue.sync {
			guard (observers.filter {
				if let observer = $0.observer {
					return observer === observer
				} else {
					return false
				}
			}).count == 0 else {
				print("AsyncSwift WARNING: observer already exists. Remove it first to change handler")
				return false
			}
			self.observers.append(Wrapper(observer: observer, handler: handler, queue: queue))
			return true
		}
	}
		
	@discardableResult public mutating func removeObserver(_ observer: AnyObject) -> Bool {
			return syncQueue.sync {
				var result = false
				self.observers = observers.filter {
					if let validObserver = $0.observer {
						if validObserver === observer {
							result = true
							return false
						}
					} else {
						result = true
						return false
					}
					return true
				}
				return result
			}
		}
	
	public var projectedValue: T? {
		get {
			switch value {
			case .success(let data):
				return data
			case .failure:
				return nil
			}
		}
		
		set {
			value = .success(newValue)
		}
	}
}
