//
//  CurrencyListViewModelInterfaces.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

protocol CurrencyViewModelInterface: class {
    var id: String { get }
    var currencyCode: String { get }
    var currencyName: String? { get }
    var amountValue: Promise<Double> { get }
    
    func updateCurrencyValue(amount: Double) throws
}

protocol CurrencyListViewModelInterface {
    func fetch() -> Promise<[CurrencyViewModelInterface]>
    func scheduleUpdate(every: EveryTimeFrame?)
}
