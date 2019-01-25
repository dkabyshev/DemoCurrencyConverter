//
//  Locale+Ext.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 23/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

extension Locale {
    /// Get a `Locale` by currencyCode
    ///
    /// - Parameter currencyCode: a currencyCode (e.g. USD)
    /// - Returns: `Locale` that matches currency or Locale.current
    static func currencyLocale(currencyCode: String) -> Locale {
        var locale = Locale.current
        if (locale.currencyCode != currencyCode) {
            let identifier = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode])
            locale = NSLocale(localeIdentifier: identifier) as Locale
        }
        return locale
    }
}
