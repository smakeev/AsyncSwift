//
//  AsyncObservable.swift
//  AsyncSwift
//
//  Created by Sergey Makeev on 03.01.2020.
//  Copyright © 2020 SOME projects. All rights reserved.
//

import Foundation
public protocol AsyncObserver {
    associatedtype ObservableType
    @discardableResult mutating func addObserver(_ observer: AnyObject, on queue: DispatchQueue?,  handler: @escaping (ObservableType) -> Void) -> Bool
    @discardableResult mutating func removeObserver(_ observer: AnyObject) -> Bool
}

@propertyWrapper
struct AsyncObservable<T>: AsyncObserver {
    public typealias ObservableType = T


    public var wrappedValue: T {
        get {
            return value
        }
        
        set {
            self.value = newValue
            self.syncQueue.sync {
                let elementsToBeDeleted = NSMutableArray()
                for element in observers {
                    let element = element as! Wrapper
                    if element.observer == nil {
                        elementsToBeDeleted.add(element)
                    } else {
                        element.handler(newValue)
                    }
                }

                for element in elementsToBeDeleted {
                    observers.remove(element)
                }

            }
        }
    }
    
    private var queue: DispatchQueue? = nil
    private var value: T
    private let syncQueue: DispatchQueue = DispatchQueue(label: "AsyncObserverSyncQueue")
    
    private class Wrapper: NSObject {
        weak var observer: AnyObject? = nil
        var handler: (T) -> Void
        var queue: DispatchQueue
        
        init(observer: AnyObject, handler: @escaping (T) -> Void, queue: DispatchQueue) {
            self.observer = observer
            self.handler  = handler
            self.queue    = queue
        }
    }
    
    private var observers = NSMutableArray() //[Wrapper]()
    
    public init(wrappedValue value: T, _ queue: DispatchQueue? = nil) {
        self.queue = queue
        self.value = value
    }
    
    @discardableResult public func addObserver(_ observer: AnyObject, on queue: DispatchQueue? = nil,  handler: @escaping (T) -> Void) -> Bool {
        return syncQueue.sync {
            guard (observers.filter {
                guard let element = $0 as? Wrapper else { return false }
                if let observer = element.observer {
                    return observer === observer
                } else {
                    return false
                }
            }).count == 0 else {
                print("AsyncSwift WARNING: observer already exists. Remove it first to change handler")
                return false
            }
            self.observers.add(Wrapper(observer: observer, handler: handler, queue: queue ?? DispatchQueue.main))
            return true
        }
    }
        
    @discardableResult public func removeObserver(_ observer: AnyObject) -> Bool {
            return syncQueue.sync {
                var elementToBeRemoved: Wrapper?
                for element in observers {
                    if let element = element as? Wrapper {
                        if element.observer === observer {
                            elementToBeRemoved = element
                        }
                    }
                }
                if let element = elementToBeRemoved {
                    observers.remove(element)
                    return true
                }
                return false
            }
        }
    
    public var projectedValue:  AsyncObservable<T> {
            return self
    }
}
