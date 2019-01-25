//
//  RevolutCurrencyConverterTests.swift
//  RevolutCurrencyConverterTests
//
//  Created by Dmytro Kabyshev on 20/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import XCTest
@testable import RevolutCurrencyConverter

class RevolutCurrencyConverterTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func test1_isDouble() {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        XCTAssert("123.00".isDouble(with: formatter, allowedDecimals: 2))
        XCTAssert("0.01".isDouble(with: formatter, allowedDecimals: 2))
        XCTAssert("1".isDouble(with: formatter, allowedDecimals: 0))
        XCTAssertFalse("1.1".isDouble(with: formatter, allowedDecimals: 0))
        XCTAssertFalse("1.123".isDouble(with: formatter, allowedDecimals: 2))
        XCTAssertFalse(".123".isDouble(with: formatter, allowedDecimals: 2))
    }
}
