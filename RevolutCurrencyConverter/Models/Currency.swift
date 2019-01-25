//
//  Currency.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

struct Currencies: Codable {
    var rates: [String: Double]
}

struct Currency: Equatable {
    var symbol: String
    var rate: Double
}
