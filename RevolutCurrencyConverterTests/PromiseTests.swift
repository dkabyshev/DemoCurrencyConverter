//
//  PromiseTests.swift
//  RevolutCurrencyConverterTests
//
//  Created by Dmytro Kabyshev on 22/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import XCTest
@testable import RevolutCurrencyConverter

enum PromiseTestsErrors: Error {
    case testError
}

extension DispatchQueueType {
    var isMain: Bool {
        return self == .main
    }
}

class PromiseTests: XCTestCase {

    @discardableResult
    private func error<T>(promise: Promise<T>, expectation: XCTestExpectation? = nil) -> Promise<T> {
        return promise.error(on: .main) { error in
            XCTAssert(Thread.current.isMainThread, "Ensure promise .error is on requested thread")
            if let error = error as? PromiseTestsErrors {
                XCTAssert(error == PromiseTestsErrors.testError)
            } else {
                XCTFail("Test error has wrong type")
            }
            expectation?.fulfill()
        }
    }
    
    private func promiseMock(on queue: DispatchQueueType = .main, resolve: Bool = true) -> Promise<String> {
        return Promise<String>(on: queue) { promise in
            XCTAssert(Thread.current.isMainThread == queue.isMain, "Ensure promise op is on requested thread")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                resolve ? promise.resolve(String(describing: self)) :
                    promise.reject(PromiseTestsErrors.testError)
            })
        }
    }

    func test1_SimpleThen() {
        let expectation = self.expectation(description: #function)
        promiseMock()
            .then(on: .background) { value in
                XCTAssert(!Thread.current.isMainThread, "Ensure .then callback is on requested thread")
                XCTAssert(value == String(describing: self))
                expectation.fulfill()
            }.error { (_) in
                XCTFail("Should not be called")
            }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test2_SimpleError() {
        let expectation = self.expectation(description: #function)
        let promise = promiseMock(on: .background, resolve: false)
            .then { _ in
                XCTFail("Should not be called")
            }
        error(promise: promise, expectation: expectation)
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test3_AlwaysAfterThen() {
        let expectation = self.expectation(description: #function)
        promiseMock(on: .background)
            .then { _ in
            }.always {
                expectation.fulfill()
            }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test4_AlwaysAfterError() {
        // Create an expectation
        let expectation = self.expectation(description: #function)
        promiseMock(on: .background, resolve: false)
            .error { _ in
            }.always {
                expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test5_MapThen() {
        let testValue = 5
        let expectation = self.expectation(description: #function)
        promiseMock(on: .background)
            .map { value in
                return Promise<Int>(on: .main) { promise in
                    XCTAssert(Thread.current.isMainThread, "Ensure promise op is on requested thread")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        promise.resolve(testValue)
                    })
                }
            }.then { value in
                XCTAssert(testValue == value)
                expectation.fulfill()
            }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test6_MapError() {
        let expectation = self.expectation(description: #function)
        let promise = promiseMock(on: .background)
            .map { value in
                return Promise<Int>(on: .main) { promise in
                    XCTAssert(Thread.current.isMainThread, "Ensure promise op is on requested thread")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                        promise.reject(PromiseTestsErrors.testError)
                    })
                }
            }
        error(promise: promise, expectation: expectation)
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test7_WithError() {
        let testValue = 5
        let expectation = self.expectation(description: #function)
        let promise = promiseMock(on: .background, resolve: false)
            .withLast(promise: Promise<Int>(on: .main) { promise in
                XCTAssert(Thread.current.isMainThread, "Ensure promise op is on requested thread")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    promise.resolve(testValue)
                })
            })
        error(promise: promise, expectation: expectation)
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func test8_WithLast() {
        let testValue = 5
        let expectation = self.expectation(description: #function)
        let withPromise = Promise<Int>(on: .main) { promise in
            XCTAssert(Thread.current.isMainThread, "Ensure promise op is on requested thread")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: {
                promise.resolve(testValue * 3)
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3, execute: {
                promise.resolve(testValue * 2)
            })
        }
        withPromise.resolve(testValue)
        promiseMock(on: .background)
            .withLast(promise: withPromise)
            .then { (pair) in
                XCTAssert(pair == (String(describing: self), testValue))
                expectation.fulfill()
        }
        waitForExpectations(timeout: 4, handler: nil)
    }
}
