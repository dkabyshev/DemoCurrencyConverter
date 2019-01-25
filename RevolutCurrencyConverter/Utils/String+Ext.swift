//
//  String+Ext.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 24/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

extension String {
    /// Look for Localized in a bundle with a key of current string value
    ///
    /// - Parameters:
    ///   - bundle: Bundle to look in (default = .main)
    ///   - tableName: it is the name of a file (e.g. SomeStrings.strings where tableName = "SomeStrings")
    /// - Returns: Localized or self as fallback
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: self, comment: "")
    }
    
    /// Check if current string value could be converted to double using `NumberFormatter` and allowedDecimals
    ///
    /// - Parameters:
    ///   - formatter: `NumberFormatter` to check string double value against
    ///   - allowedDecimals: number of decimal allowed for a double
    /// - Returns: true if current string value satisfies all constraints
    func isDouble(with formatter: NumberFormatter, allowedDecimals: Int = 2) -> Bool {
        var numberOfDecimalDigits = 0
        if let dotIndex = self.index(of: ".") {
            numberOfDecimalDigits = self.distance(from: dotIndex, to: self.endIndex) - 1
        }
        return formatter.number(from: self.isEmpty ? "0" : self)?.doubleValue != nil && numberOfDecimalDigits <= allowedDecimals
    }
}
