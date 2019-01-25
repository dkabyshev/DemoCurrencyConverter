//
//  CurrencyListViewModel.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

enum CurrencyViewModelErrors: Error, LocalizedError {
    case negativeAmount
    
    var errorDescription: String? {
        switch self {
        case .negativeAmount:
            return "Negative currency ammount is not allowed".localized()
        }
    }
}

/// Single currency view model
/// Each time currency gets new rate an update is propagated via promise
final class CurrencyViewModel: CurrencyViewModelInterface {
    let id = UUID().uuidString
    let currencyCode: String
    let currencyName: String?
    let amountValue: Promise<Double>
    let baseCurrencyValue: Promise<Double>
    private let userInputAmount: Promise<Double>
    private let updateQueue = DispatchQueue(label: "CurrencyViewModel")
    
    /// Create `CurrencyViewModel`
    ///
    /// - Parameters:
    ///   - initial: initial info about `Currency`
    ///   - ratePromise: promise that expects to send every update about `Currency` info (rate change)
    ///   - valuePromise: promise that expects to send amount in base currency (EUR) to display in currency currency
    init(initial: Currency,
         ratePromise: Promise<Currency>,
         valuePromise: Promise<Double>
    ) {
        let locale = Locale.currencyLocale(currencyCode: initial.symbol)
        self.currencyName = locale.localizedString(forCurrencyCode: initial.symbol)
        self.currencyCode = initial.symbol
        // Combine two promises: one with currency rate and second one amount user set
        self.amountValue = Promise<Double>() { _ in }
        self.userInputAmount = Promise<Double>() { _ in }
        self.baseCurrencyValue = userInputAmount.withLast(promise: ratePromise).map({ (pair) in
            return Promise<Double>(on: .main) { resultPromise in
                resultPromise.resolve(Double(pair.0 / pair.1.rate.greaterZero(or: 1)))
            }
        })
        // Update total amount when new value got input from user using latest rate
        valuePromise.withLast(promise: ratePromise).then(on: .main) { [weak self] (pair) in
            self?.updateQueue.async {
                self?.amountValue.resolve(Double(pair.1.rate * pair.0))
            }
        }
        // Update total amount when new rate got fetched using latest input from user
        ratePromise.withLast(promise: valuePromise).then(on: .main) { [weak self] (pair) in
            self?.updateQueue.async {
                self?.amountValue.resolve(Double(pair.0.rate * pair.1))
            }
        }
    }
    
    /// Change base amount of current currency (eq. of 1 eur) to some amount
    ///
    /// - Parameter amount: amount of currency (e.g. 100 USD, 200 PLN etc)
    func updateCurrencyValue(amount: Double) throws {
        guard amount >= 0 else { throw CurrencyViewModelErrors.negativeAmount } // negative is not allowed
        userInputAmount.resolve(amount)
    }
}

/// ViewModel responsible for fetching and pushing an array of currency view models to a listener
class CurrencyListViewModel: CurrencyListViewModelInterface {
    private let service: CurrencyServiceInterface
    private var currenciesPromises: [String: Promise<Currency>] = [:]
    private let amountPromise: Promise<Double>
    private let resultPromise = Promise<[CurrencyViewModelInterface]>() { _ in }
    private var timer: BackgroundTimer!
    
    init(service: CurrencyServiceInterface, initialBaseAmount: Double = 1.0) {
        self.service = service
        self.amountPromise = Promise<Double>() { _ in }
        self.amountPromise.resolve(initialBaseAmount)
    }
    
    /// Fetch inital list of currencies
    ///
    /// - Returns: array of `CurrencyViewModelInterface`
    func fetch() -> Promise<[CurrencyViewModelInterface]> {
        service.fetchCurrencies()
            .then { [weak self] currencies in // run only once to setup promise dict
                guard let self = self else { return }
                var resultViewModels: [CurrencyViewModelInterface] = []
                currencies.forEach { currency in
                    let promise = Promise<Currency>() { promise in
                        promise.resolve(currency)
                    }
                    let viewModel = CurrencyViewModel(initial: currency, ratePromise: promise, valuePromise: self.amountPromise)
                    viewModel.baseCurrencyValue.then { [weak self] in self?.amountPromise.resolve($0) }
                    resultViewModels.append(viewModel)
                    self.currenciesPromises[currency.symbol] = promise
                }
                self.resultPromise.resolve(resultViewModels)
            }.error { [weak self] (error) in
                self?.resultPromise.reject(error)
        }
        return resultPromise
    }
    
    /// Fetch new currency rates every `EveryTimeFrame` interval
    /// and update listener via `CurrencyViewModel`
    ///
    /// - Returns: array of `CurrencyViewModelInterface`
    func scheduleUpdate(every: EveryTimeFrame? = nil) {
        guard let every = every, timer == nil else {
            return
        }
        timer = BackgroundTimer(timeInterval: every) { [weak self] in
            self?.service.fetchCurrencies()
                .then { [weak self] currencies in // update each promise with new value
                    currencies.forEach { currency in
                        self?.currenciesPromises[currency.symbol]?.resolve(currency)
                    }
                }
        }
        timer.resume()
    }
}
