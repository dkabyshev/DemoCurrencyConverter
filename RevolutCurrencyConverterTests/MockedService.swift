//
//  MockedService.swift
//  RevolutCurrencyConverterTests
//
//  Created by Dmytro Kabyshev on 24/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation
@testable import RevolutCurrencyConverter

final class MockedService: CurrencyServiceInterface {
    private let currencies: [Currency]
    
    init(currencies: [Currency]) {
        self.currencies = currencies
    }
    
    func fetchCurrencies() -> Promise<[Currency]> {
        return Promise<[Currency]>() { promise in
            promise.resolve(self.currencies)
        }
    }
}

final class MockedServiceSerial: CurrencyServiceInterface {
    private var currencies: [[Currency]]
    
    init(currencies: [[Currency]]) {
        self.currencies = currencies
    }
    
    func fetchCurrencies() -> Promise<[Currency]> {
        return Promise<[Currency]>() { promise in
            if let first = self.currencies.first {
                promise.resolve(first)
                self.currencies.remove(at: 0)
            }
        }
    }
}

final class MockedServiceError: CurrencyServiceInterface {
    func fetchCurrencies() -> Promise<[Currency]> {
        return Promise<[Currency]>() { promise in
            promise.reject(CurrencyServiceErrors.dataNotValid)
        }
    }
}
