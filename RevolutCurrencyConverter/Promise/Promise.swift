//
//  Promise.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 20/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

typealias Failure = (Error) -> Void
typealias RejectAsPromise<T> = (Error) -> Promise<T>
typealias Success<T> = (T) throws -> Void
typealias Fullfill<T> = (Promise<T>) throws -> Void
typealias Listener<T> = (Result<T>) -> Void

/// Simple promise utility class
/// Usage:
///```swift
///     let promise = Promise<UIImage>(on: .background)
///     someSyncTask() { result, error in
///         if let error = error {
///             promise.reject(error)
///         } else {
///             promise.resolve(result)
///         }
///     }
///```
class Promise<T> {
    /// Holds last successful result
    private var lastResult: T?
    /// Queue on which main promise task will be executed
    private let operationQueue: DispatchQueueType
    /// Closure for a main promise task
    private let task: Fullfill<T>?
    /// An array of listeners for current promise
    private var listeners: [Listener<T>] = []

    init(on queue: DispatchQueueType = .main, _ task: @escaping Fullfill<T>) {
        self.operationQueue = queue
        self.task = task
    }
    
    /// Resolve current promise with success result
    ///
    /// - Parameter result: result of type T
    func resolve(_ result: T) {
        lastResult = result
        listeners.forEach { $0(.success(result)) }
    }
    
    /// Reject current promise with error
    ///
    /// - Parameter result: `Error` to be propagated to all listeners
    func reject(_ error: Error) {
        listeners.forEach { $0(.failure(error)) }
    }
    
    /// Internal function to add a listener to task result
    ///
    /// - Parameter callback: listener callback
    private func addListener(_ callback: @escaping Listener<T>) {
        listeners.append(callback)
    }
    
    /// Run the task body on `operationQueue`.
    /// The task will be executed as sync or directly if the thread is Main
    /// and we were requested to run on main
    ///
    /// - Parameters:
    ///   - resolve: callback for success with value
    ///   - reject: callback for failure with error
    private func runTask(isSync: Bool = false) {
        let block = {
            do { // We allow body to throw, but we convert an exception into rejected one
                try self.task?(self)
            } catch let err {
                self.reject(err)
            }
        }
        isSync ? block() : operationQueue.dispatchQueue.async { block() }
    }
    
    /// Internal method to wrap a promise and run its task
    ///
    /// - Parameters:
    ///   - queue: type (`DispatchQueueType`) of async queue to execute result `success` or `failure`
    ///   - closure: callback to execute that transforms into another promise
    /// - Returns: new Promise<U>
    private func chainable(on queue: DispatchQueueType = .main, _ success: Success<T>?, _ failure: Failure?) -> Promise<T> {
        let wrapperPromise = Promise<T>() { _ in
        }
        self.addListener { (result) in
            switch result {
            case let .success(value):
                queue.dispatchQueue.async {
                    do { // We allow body to throw, but we convert an exception into rejected one
                        try success?(value)
                        wrapperPromise.resolve(value)
                    } catch let error {
                        failure?(error)
                        wrapperPromise.reject(error)
                    }
                }
            case let .failure(error):
                queue.dispatchQueue.async { failure?(error) }
                wrapperPromise.reject(error)
            }
        }
        self.runTask()
        return wrapperPromise
    }
    
    /// Internal method to wrap a promise and run its task
    ///
    /// - Parameters:
    ///   - queue: type (`DispatchQueueType`) of async queue to execute result `closure`
    ///   - closure: callback to execute that transforms into another promise
    /// - Returns: new Promise<U>
    private func chainable<U>(on queue: DispatchQueueType = .main, _ closure: @escaping (T) throws -> Promise<U>) -> Promise<U> {
        let wrapperPromise = Promise<U>() { _ in
        }
        self.addListener { (result) in
            switch result {
            case let .success(value):
                queue.dispatchQueue.async {
                    do { // We allow body to throw, but we convert an exception into rejected one
                        let promise = try closure(value)
                        promise.addListener({ (result) in
                            switch result {
                            case let .success(value): wrapperPromise.resolve(value)
                            case let .failure(error): wrapperPromise.reject(error)
                            }
                        })
                        promise.runTask(isSync: true)
                    } catch let err {
                        wrapperPromise.reject(err)
                    }
                }
            case let .failure(error): wrapperPromise.reject(error)
            }
            
        }
        self.runTask()
        return wrapperPromise
    }
    
    /// .then operator executes `closure` in case of success of original task
    /// `closure` is executed on provided `queue`
    ///
    /// - Parameters:
    ///   - queue: type (`DispatchQueueType`) of async queue to execute result `closure`
    ///   - closure: `Success<T>` callback to execute if original promise task was successful
    /// - Returns: return a new chainable promise
    @discardableResult func then(on queue: DispatchQueueType = .main, _ closure: @escaping Success<T>) -> Promise<T> {
        return self.chainable(on: queue, closure, nil)
    }
    
    /// .mapThen operator executes `closure` in case of success of an original task
    /// `closure` is executed on provided `queue`
    /// Used to transform one promise into another
    ///
    /// - Parameters:
    ///   - queue: type (`DispatchQueueType`) of async queue to execute result `closure`
    ///   - closure: callback to execute if original promise task was successful, that return a new Promise
    /// - Returns: return a new chainable promise
    @discardableResult func map<U>(on queue: DispatchQueueType = .main, _ closure: @escaping (T) -> Promise<U>) -> Promise<U> {
        return chainable(closure)
    }
    
    /// .error operator executes `closure` in case of failure of an original task
    /// `closure` is executed on provided `queue`
    ///
    /// - Parameters:
    ///   - queue: type (`DispatchQueueType`) of async queue to execute result `closure`
    ///   - closure: `Failure` callback to execute if original promise task failed
    /// - Returns: return a new chainable promise
    @discardableResult func error(on queue: DispatchQueueType = .main, _ closure: @escaping Failure) -> Promise<T> {
        return self.chainable(on: queue, nil, closure)
    }
    
    /// .always operator executes regardless of resulting value of an original task
    /// `closure` is executed on provided `queue`
    ///
    /// - Parameters:
    ///   - queue: type (`DispatchQueueType`) of async queue to execute result `closure`
    ///   - closure: callback to execute when original task is done
    /// - Returns: return a new chainable promise
    @discardableResult func always(on queue: DispatchQueueType = .main, _ closure: @escaping () -> Void) -> Promise<T> {
        return self.chainable(on: queue, { _ in closure() }, { _ in closure() })
    }
    
    /// .withLast operator executes only, and only when current promise amd if `promise` has last success value
    /// It emits a pair using the last success value from `promise` once it gets triggerd by current one
    /// But only when both promises has results
    ///
    /// - Parameter promise: other promise to watch for results and propagate a pair (T, U) where T us our type, and U is the other
    /// - Returns: new chainable promise with type (T, U)
    @discardableResult func withLast<U>(promise: Promise<U>) -> Promise<(T, U)> {
        let wrapperPromise = Promise<(T, U)>() { _ in
        }
        
        // Listen to our updates
        self.addListener { [weak promise] (result) in
            switch result {
            case let .success(value):
                if let otherValue = promise?.lastResult {
                    wrapperPromise.resolve((value, otherValue))
                }
            case let .failure(error):
                wrapperPromise.reject(error)
            }
        }

        promise.runTask()
        self.runTask()
        return wrapperPromise
    }
}
