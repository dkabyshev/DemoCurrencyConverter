//
//  CurrencyServiceInterface.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 20/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

protocol CurrencyServiceInterface {
    func fetchCurrencies() -> Promise<[Currency]>
}
