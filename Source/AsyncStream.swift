//
//  AsyncStream.swift
//  AsyncSwift
//
//  Created by Sergey Makeev on 04.12.2019.
//  Copyright © 2019 SOME projects. All rights reserved.
//

import Foundation

public typealias AStream  = AsyncStream
public typealias MAStream = MutableAsyncStream


public protocol PublicStreamProtocol {

}

internal protocol InternalStreamProtocol: PublicStreamProtocol {
 func apply();
}

public enum AStreamErrors: Error {
	case StreamClosed
}

public class AsyncStream<Type>: PublicStreamProtocol {

	public init() {
		syncQueue.setSpecific(key: syncQueueKey, value: ())
	}

	private var filters: [(Type?) -> Bool] = Array.init()
	public func filter(_ filter: @escaping (Type?) -> Bool) {
		syncQueue.sync {
			filters.append(filter)
		}
	}
	
	private var maps: [(Type?) -> Type?] = Array.init()
	public func map(_ map: @escaping (Type?) -> Type?) {
		syncQueue.sync {
			maps.append(map)
		}
	}

	fileprivate var _lastValue: Type? = nil
	public var lastValue: Type? {
		get {
			return syncQueue.sync {
				return _lastValue
			}
		}
	}
	
	private var _error: Error? = nil
	public var error: Error? {
		get {
			return syncQueue.sync {
				return _error
			}
		}
	}
	
	private var _onError: [(Error) -> Void] = [(Error) -> Void]()
	private var _onErrorOnce: [(Error) -> Void] = [(Error) -> Void]()
	@discardableResult public func onError(_ handler: @escaping (Error) -> Void) -> AsyncStream<Type> {
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				_onError.append(handler)
			}
		} else {
			_onError.append(handler)
		}
		return self
	}
	@discardableResult public func onErrorOnce(_ handler: @escaping (Error) -> Void) -> AsyncStream<Type> {
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				_onErrorOnce.append(handler)
			}
		} else {
			_onErrorOnce.append(handler)
		}
		return self
	}


	private var _onValue: [(Type?) -> Void] = [(Type?) -> Void]()
	private var _onValueOnce: [(Type?) -> Void] = [(Type?) -> Void]()
	@discardableResult public func listen(_ handler: @escaping (Type?) -> Void)  -> AsyncStream<Type> {
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				_onValue.append(handler)
			}
		}
		else {
			_onValue.append(handler)
		}
		return self
	}
	@discardableResult public func listenOnce(_ handler: @escaping (Type?) -> Void)  -> AsyncStream<Type> {
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				_onValueOnce.append(handler)
			}
		} else {
			_onValueOnce.append(handler)
		}
		return self
	}

	private var _onClose: [() ->Void] = [() -> Void]()
	private var _onCloseOnce: [() ->Void] = [() -> Void]()
	@discardableResult public func onClose(_ handler: @escaping () -> Void)  -> AsyncStream<Type> {
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				_onClose.append(handler)
			}
		} else {
			_onClose.append(handler)
		}
		return self
	}
	@discardableResult public func onCloseOnce(_ handler: @escaping () -> Void)  -> AsyncStream<Type> {
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				_onCloseOnce.append(handler)
			}
		} else {
			_onCloseOnce.append(handler)
		}
		return self
	}

	private var _arraySize: UInt = 0
	public var arraySize: UInt {
		get {
			return syncQueue.sync {
				return _arraySize
			}
		}
		
		set {
			syncQueue.sync {
				_arraySize = newValue
			}
		}
	}

	private var _array: [Type?] = [Type?]()
	public func toArray() -> [Type?] {
		return _array
	}
	
	fileprivate var body: (((Type?) throws -> Void) throws -> Void)?
	lazy public var  provider: (Type?) throws -> Void = { [weak self] providee in
		guard let validSelf = self else { return }

		guard !validSelf.isClosed else { throw AStreamErrors.StreamClosed }
		
		var value: Type? = providee
		
		validSelf.syncQueue.sync {
			//check for filters
			for filter in validSelf.filters {
				if filter(providee) == false {
					return
				}
			}
			
			//use maps
			for map in validSelf.maps {
				value = map(value)
			}
		
			for handler in validSelf._onValue {
				handler(value)
			}

			for handler in validSelf._onValueOnce {
				handler(value)
			}
		
			for nextStream in validSelf.nextStreams {
				try? nextStream.provider(value)
			}
			
			validSelf._onValueOnce.removeAll()
			validSelf._active = true
			validSelf._lastValue = value
			
			for bridge in validSelf.bridges {
				bridge.apply()
			}
			
			if validSelf._arraySize == 0 { return }
			if validSelf._array.count == validSelf._arraySize {
				validSelf._array.remove(at: 0)
			}
			validSelf._array.append(value)
		}
	}
	fileprivate var syncQueue: DispatchQueue = DispatchQueue(label: "AsyncStreamSyncQueue")
	fileprivate var syncQueueKey = DispatchSpecificKey<Void> ()
	internal var agent: AsyncStream<Type>? = nil

	public func start(autoStop: Bool = false) {
		guard !isClosed else { return }
		guard !isActive else { return }
		syncQueue.sync {
			agent   = self
			_active = true
		}
		var shouldStop = autoStop
		DispatchQueue.global().async {
			do {
				try self.body?(self.provider)
			} catch {
				switch error {
				case AStreamErrors.StreamClosed:
					print("streamClosed")
					shouldStop = false
				default:
					shouldStop = true

					for handler in self._onError {
						handler(error)
					}
					
					for handler in self._onErrorOnce {
						handler(error)
					}
					self.syncQueue.sync {
						self._error = error
						self._onErrorOnce.removeAll()
					}
				}
			}
			
			if shouldStop {
				self.stop()
			}
		}
	}

	internal var _active: Bool = false
	public var isActive: Bool {
		get {
			return syncQueue.sync {
				return _active
			}
		}
	}

	internal var _closed: Bool = false
	public var isClosed: Bool {
		get {
			return syncQueue.sync {
				return _closed
			}
		}
	}
	
	private func _stop() {
		_closed = true
		for handler in _onClose {
			handler()
		}
		
		for handler in _onCloseOnce {
			handler()
		}
		_onCloseOnce.removeAll()
		
		_active = false
		agent   = nil
	}
	
	public func stop() {
		syncQueue.sync {
			_stop()
		}
	}
	
	public func listenTo(_ stream: AsyncStream<Type>) {
		stream.nextStream(self)
	}
	
	private var nextStreams = Array<AsyncStream<Type>>.init()
	public func nextStream(_ stream: AsyncStream<Type>) {
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				if (nextStreams.filter { $0 === stream }.count == 0) {
					self.nextStreams.append(stream)
				}
			}
		} else {
			if (nextStreams.filter { $0 === stream }.count == 0) {
				self.nextStreams.append(stream)
			}
		}
	}
	
	private var bridges = [InternalStreamProtocol]()
	@discardableResult public func bridgeTo<Type1>(_ stream: PublicStreamProtocol, withRule rule: @escaping (Type) -> Type1) -> AStream<Type> {
		let bridge = StreamBridge<Type, Type1>(with: rule)
		bridge.streamFrom = self
		bridge.streamTo   = stream as? AsyncStream<Type1>
		if DispatchQueue.getSpecific(key: self.syncQueueKey) == nil {
			syncQueue.sync {
				bridges.append(bridge)
			}
		} else {
			bridges.append(bridge)
		}
		return self
	}
	
	@discardableResult public func bridgeFrom<Type1>(_ stream: PublicStreamProtocol, withRule rule: @escaping (Type1) -> Type) -> AStream<Type> {
		guard let validStream = stream as? AStream<Type1> else { return self }
		validStream.bridgeTo(self, withRule: rule)
		return self
	}
}

public class MutableAsyncStream<Type>: AsyncStream<Type> {

	private var _hasBeenReopened: Bool = false
	public  var hasBeenReopened:  Bool  {
		get {
			syncQueue.sync {
				return _hasBeenReopened
			}
		}
	}

	private var boddies: [((Type) throws -> Void) throws -> Void] = [((Type) throws -> Void) throws -> Void]()

	func addBody(_ body: @escaping (((Type) throws -> Void) throws -> Void)) {
		syncQueue.sync {
			if self.body == nil &&
				boddies.count == 0 {
				self.body = body
			} else {
				boddies.append(body)
			}
		}
	}

	override public func start(autoStop: Bool = false) {
		var shouldExit = false
		syncQueue.sync {
			if _active {
				shouldExit = true
				return
			}
			if body == nil &&
			   boddies.count == 0 {
			   
			   shouldExit = true
			   return
			} else if body == nil {
				body = boddies.remove(at: 0)
			}
		}
		if shouldExit { return }
		
		super.start(autoStop: autoStop)
	}

	//Will reopen stream if there are not used bodies.
	func reopen(autoStop: Bool = false) {
		guard isClosed else  { return }
		var shouldStart: Bool = false
		syncQueue.sync {
			if self.boddies.count > 0 {
				_closed = false
				self.body = self.boddies.remove(at:0)
				shouldStart = true
				_hasBeenReopened = true
			 }
		}
		if shouldStart {
			start(autoStop: true)
		}
	}
}

internal class StreamBridge<Type1, Type2>: InternalStreamProtocol {
	
	public func apply() {
		guard let streamFrom = streamFrom        else { return }
		guard let  input = streamFrom._lastValue else { return }
		guard let output = rule?(input)           else { return }
		try? streamTo?.provider(output)
	}
	
	public private(set) var rule: ((Type1) -> Type2)?
	public init(with rule: @escaping (Type1) -> Type2) {
		self.rule = rule
	}
	
	public weak var streamFrom: AStream<Type1>?
	public weak var streamTo:   AStream<Type2>?
}
