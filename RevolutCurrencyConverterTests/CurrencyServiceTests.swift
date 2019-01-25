//
//  CurrencyServiceTests.swift
//  RevolutCurrencyConverterTests
//
//  Created by Dmytro Kabyshev on 24/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import XCTest
@testable import RevolutCurrencyConverter

final class MockedSession: NetworkingSession {
    private let currencies: [Currency]
    
    init(currencies: [Currency]) {
        self.currencies = currencies
    }
    
    func request(_ router: NetworkRouter) -> Promise<Data> {
        var dict: [String: Any] = [:]
        currencies.forEach { dict[$0.symbol] = $0.rate }
        let jsonData = try! JSONSerialization.data(withJSONObject: ["rates": dict], options: .prettyPrinted)
        return Promise<Data>() { promise in
            promise.resolve(jsonData)
        }
    }
}

final class MockedSessionError: NetworkingSession {
    func request(_ router: NetworkRouter) -> Promise<Data> {
        return Promise<Data>() { promise in
            promise.reject(CurrencyServiceErrors.dataNotValid)
        }
    }
}

class CurrencyServiceTests: XCTestCase {

    func test1_fetchCurrencies() {
        let expectation = self.expectation(description: #function)
        let currenciesMock = [
            Currency(symbol: "CHF", rate: 1.1318),
            Currency(symbol: "USD", rate: 1.1)
        ]
        let currencyService = CurrencyService(session: MockedSession(currencies: currenciesMock))
        currencyService.fetchCurrencies()
            .then { (currencies) in
                XCTAssert(currencies == currenciesMock, "CurrencyService fetch reselt doesn't match mocked")
                expectation.fulfill()
            }
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func test2_fetchCurrencies_error() {
        let expectation = self.expectation(description: #function)
        let currencyService = CurrencyService(session: MockedSessionError())
        currencyService.fetchCurrencies()
            .then { _ in
            }.error { _ in
                expectation.fulfill()
            }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
