//
//  ViewModelTests.swift
//  RevolutCurrencyConverterTests
//
//  Created by Dmytro Kabyshev on 24/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import XCTest
@testable import RevolutCurrencyConverter

class ViewModelTests: XCTestCase {

    func test1_CurrencyViewModel_amount() {
        let expectation = self.expectation(description: #function)
        let currencyCode = "USD"
        let rate: Double = 1.12
        let baseValue: Double = 100
        let currency = Currency(symbol: currencyCode, rate: rate)
        let promiseCurrency = Promise<Currency>() { _ in }
        let promiseValue = Promise<Double>() { _ in }
        let viewModel = CurrencyViewModel(initial: currency,
                                          ratePromise: promiseCurrency,
                                          valuePromise: promiseValue)
        let locale = Locale.currencyLocale(currencyCode: currencyCode)
        XCTAssert(viewModel.currencyName == locale.localizedString(forCurrencyCode: currencyCode))
        XCTAssert(viewModel.currencyCode == currencyCode)
        viewModel.amountValue.then { (value) in
            XCTAssert(value == (baseValue * rate))
            expectation.fulfill()
        }
        promiseCurrency.resolve(currency)
        promiseValue.resolve(baseValue)
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test2_CurrencyViewModel_baseValue() {
        let expectation = self.expectation(description: #function)
        let currencyCode = "USD"
        let rate: Double = 1.12
        let baseValue: Double = 101
        let currency = Currency(symbol: currencyCode, rate: rate)
        let promiseCurrency = Promise<Currency>() { _ in }
        let promiseValue = Promise<Double>() { _ in }
        let viewModel = CurrencyViewModel(initial: currency,
                                          ratePromise: promiseCurrency,
                                          valuePromise: promiseValue)
        viewModel.baseCurrencyValue.then { (value) in
            XCTAssert(value == (baseValue / rate))
            expectation.fulfill()
        }
        promiseCurrency.resolve(currency)
        do { try viewModel.updateCurrencyValue(amount: baseValue) }
        catch { XCTFail("Failed: \(error.localizedDescription)") }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test3_CurrencyViewModel_baseValue_negative() {
        let expectation = self.expectation(description: #function)
        let currencyCode = "USD"
        let rate: Double = 1.12
        let baseValue: Double = -101
        let currency = Currency(symbol: currencyCode, rate: rate)
        let promiseCurrency = Promise<Currency>() { _ in }
        let promiseValue = Promise<Double>() { _ in }
        let viewModel = CurrencyViewModel(initial: currency,
                                          ratePromise: promiseCurrency,
                                          valuePromise: promiseValue)
        promiseCurrency.resolve(currency)
        do { try viewModel.updateCurrencyValue(amount: baseValue) }
        catch {
            if let error = error as? CurrencyViewModelErrors {
                XCTAssert(error == CurrencyViewModelErrors.negativeAmount)
            } else {
                XCTFail("Test error has wrong type")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test4_CurrencyListViewModel_fetch() {
        let expectation = self.expectation(description: #function)
        let currenciesMock = [
            Currency(symbol: "ZAR", rate: 3),
            Currency(symbol: "CHF", rate: 1.1318),
            Currency(symbol: "USD", rate: 1.1),
            Currency(symbol: "AUD", rate: 2),
            ]
        let viewModel = CurrencyListViewModel(service: MockedService(currencies: currenciesMock))
        viewModel.fetch()
            .then { (currencies) in
                XCTAssert(currencies.count == currenciesMock.count)
                for (index, value) in currencies.enumerated() {
                    XCTAssert(value.currencyCode == currenciesMock[index].symbol)
                }
                expectation.fulfill()
            }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test5_CurrencyListViewModel_schedule() {
        let expectation = self.expectation(description: #function)
        let currenciesMock = [
            Currency(symbol: "ZAR", rate: 3),
        ]
        var timerCount = 0
        let viewModel = CurrencyListViewModel(service: MockedService(currencies: currenciesMock))
        viewModel.fetch()
            .then { (currencies) in
                currencies[0].amountValue.then({ (_) in
                    timerCount += 1
                    if timerCount == 2 {
                        expectation.fulfill()
                    }
                })
                viewModel.scheduleUpdate(every: .seconds(1))
        }
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func test6_CurrencyListViewModel_error() {
        let expectation = self.expectation(description: #function)
        let viewModel = CurrencyListViewModel(service: MockedServiceError())
        viewModel.fetch()
            .error { (currencies) in
                expectation.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
