//
//  CurrencyService.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

enum CurrencyServiceErrors: Error {
    case dataNotValid
}

final class CurrencyService: CurrencyServiceInterface {
    private let session: NetworkingSession
    
    init(session: NetworkingSession = URLSession.shared) {
        self.session = session
    }
    
    func fetchCurrencies() -> Promise<[Currency]> {
        return session
            .request(CurrencyRouter.currencies(base: .eur))
            .map({ (data) in
                let promise = Promise<[Currency]>(on: .background) { promise in
                    // Map data to Currencies to get to dictionary with rates
                    let currencies = try JSONDecoder().decode(Currencies.self, from: data)
                    // Map dictionary of rates to array of Currency models
                    let converted = try currencies.rates.keys.sorted()
                        .filter { currencies.rates[$0] != nil }
                        .map { key throws -> Currency  in
                            guard let rate = currencies.rates[key], rate > 0 else {
                                throw CurrencyServiceErrors.dataNotValid
                            }
                            return Currency(symbol: key, rate: rate)
                            
                    }
                    promise.resolve(converted)
                }
                return promise
            })
    }
}
