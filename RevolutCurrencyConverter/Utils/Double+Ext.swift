//
//  Double+Ext.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 22/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

extension Double {
    
    /// Utility method that ensures value greater zero
    ///
    /// - Parameter value: value to use if current double value is below zero
    /// - Returns: current value or `value`
    func greaterZero(or value: Double) -> Double {
        return self > 0 ? self : value
    }
}
