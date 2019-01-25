//
//  CurrencyListDataSourceTests.swift
//  RevolutCurrencyConverterTests
//
//  Created by Dmytro Kabyshev on 24/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import XCTest
@testable import RevolutCurrencyConverter

/// TableView with no aciton on move and scroll to, to test item movements without real UI
final class MockTableView: UITableView {
    override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
    }
    
    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
    }
}

final class CurrencyListViewModelNoTimer: CurrencyListViewModel {
    override func scheduleUpdate(every: EveryTimeFrame? = nil) {
    }
}

class CurrencyListDataSourceTests: XCTestCase {
    let tableView = MockTableView(frame: CGRect.zero)
    
    override func setUp() {
        tableView.register(cellType: CurrencyCell.self)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Test that inital fetch of rates gets properly displayed
    func test1_Load() {
        let expectation = self.expectation(description: #function)
        let currenciesMock = [
            Currency(symbol: "ZAR", rate: 3),
            Currency(symbol: "CHF", rate: 1.1318),
            Currency(symbol: "USD", rate: 1.1),
            Currency(symbol: "AUD", rate: 2),
            ]
        expectation.expectedFulfillmentCount = currenciesMock.count
        let mockedService = MockedService(currencies: currenciesMock)
        var dataSource: CurrencyListDataSource! = nil
        let initialBaseAmount: Double = 10
        let viewModel = CurrencyListViewModelNoTimer(service: mockedService, initialBaseAmount: initialBaseAmount)
        var expectationsHash: [String: Any] = [:]
        
        dataSource = CurrencyListDataSource(viewModel: viewModel, dataReload: {
            let count = dataSource.tableView(self.tableView, numberOfRowsInSection: 0)
            XCTAssert(count == currenciesMock.count) // verify total number
            for (index, currency) in currenciesMock.enumerated() {
                let cell = dataSource.tableView(self.tableView, cellForRowAt: IndexPath(row: index, section: 0))
                let cellViewModel = dataSource.viewModels[index]
                if let cell = cell as? CurrencyCell {
                    // Verify cell's content with viewmodel
                    XCTAssert(cell.currencySymbol.text == currency.symbol)
                    XCTAssert(cell.currencyName.text == cellViewModel.currencyName)
                    cellViewModel.amountValue.then({ (value) in
                        // Verify currency value
                        let str = cell.formatter.string(from: NSNumber(value: value))
                        XCTAssert(cell.textInput.text == str)
                        if expectationsHash[currency.symbol] == nil {
                            expectationsHash[currency.symbol] = true
                            expectation.fulfill()
                        }
                    })
                } else {
                    XCTFail("Wrong cell, not a CurrencyCell")
                }
            }
        }) { (_) in
        }
        dataSource.load { (error) in
            XCTAssertNil(error)
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    /// Test that subsequent fetch of new rate update the cell value
    func test2_Update() {
        let expectation = self.expectation(description: #function)
        let currenciesMock = [
            [Currency(symbol: "USD", rate: 1.1)],
            [Currency(symbol: "USD", rate: 1.2)],
            [Currency(symbol: "USD", rate: 1.3)],
            [Currency(symbol: "USD", rate: 1.0)],
        ]
        let mockedService = MockedServiceSerial(currencies: currenciesMock)
        var dataSource: CurrencyListDataSource! = nil
        let initialBaseAmount: Double = 10
        let viewModel = CurrencyListViewModel(service: mockedService, initialBaseAmount: initialBaseAmount)
        var valuesHash: [Double: Bool] = [:]
        var valuesExpectedHash: [Double: Bool] = [11:true, 12: true, 13: true, 10: true]
        
        dataSource = CurrencyListDataSource(viewModel: viewModel, dataReload: {
            let cell = dataSource.tableView(self.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            let cellViewModel = dataSource.viewModels[0]
            if let cell = cell as? CurrencyCell {
                cellViewModel.amountValue.then({ (value) in
                    // Verify currency value
                    let str = cell.formatter.string(from: NSNumber(value: value))
                    XCTAssert(cell.textInput.text == str)
                    valuesHash[value] = true
                    if valuesHash.keys.count == 4 {
                        valuesHash.keys.forEach({ (key) in
                            XCTAssert(valuesExpectedHash[key] == true)
                        })
                        expectation.fulfill()
                    }
                })
            } else {
                XCTFail("Wrong cell, not a CurrencyCell")
            }
        }) { (_) in
        }
        dataSource.load { (error) in
            XCTAssertNil(error)
        }
        waitForExpectations(timeout: 6, handler: nil)
    }

    /// Test that selected input moves to the top
    func test3_Move() {
        let expectation = self.expectation(description: #function)
        let currenciesMock = [
            Currency(symbol: "ZAR", rate: 3),
            Currency(symbol: "CHF", rate: 1.1318),
            Currency(symbol: "USD", rate: 1.1),
            Currency(symbol: "AUD", rate: 2),
            ]
        let mockedService = MockedService(currencies: currenciesMock)
        var dataSource: CurrencyListDataSource! = nil
        let initialBaseAmount: Double = 10
        let viewModel = CurrencyListViewModelNoTimer(service: mockedService, initialBaseAmount: initialBaseAmount)

        dataSource = CurrencyListDataSource(viewModel: viewModel, dataReload: {
            let count = dataSource.tableView(self.tableView, numberOfRowsInSection: 0)
            XCTAssert(count == currenciesMock.count) // verify total number
            let cell = dataSource.tableView(self.tableView, cellForRowAt: IndexPath(row: 3, section: 0))
            var cellViewModel = dataSource.viewModels[3]
            
            if let cell = cell as? CurrencyCell {
                XCTAssert(cell.currencySymbol.text == currenciesMock[3].symbol) // verify AUD at 3 postion in both source
                XCTAssert(cellViewModel.currencyCode == currenciesMock[3].symbol) // verify AUD at 3 postion in both source
                cell.cellDidBecomeFirstResponder?()
                // Not we expect 3 cell to become 0
                if let cell = dataSource.tableView(self.tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? CurrencyCell {
                    cellViewModel = dataSource.viewModels[0]
                    XCTAssert(cellViewModel.currencyCode == currenciesMock[3].symbol) // verify AUD at 3 original and 0 in our
                    XCTAssert(cell.currencySymbol.text == currenciesMock[3].symbol) //verify AUD at 3 original and 0 in our
                    expectation.fulfill()
                } else {
                    XCTFail("Wrong cell, not a CurrencyCell")
                }
            } else {
                XCTFail("Wrong cell, not a CurrencyCell")
            }
        }) { (_) in
        }
        dataSource.load { (error) in
            XCTAssertNil(error)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    /// Test that user value input get properly propagates to all cells
    func test4_UserInput() {
        let expectation = self.expectation(description: #function)
        let currenciesMock = [
            Currency(symbol: "ZAR", rate: 3),
            Currency(symbol: "CHF", rate: 1.1318),
            Currency(symbol: "USD", rate: 1.1),
            Currency(symbol: "AUD", rate: 2),
            ]
        let mockedService = MockedService(currencies: currenciesMock)
        var dataSource: CurrencyListDataSource! = nil
        let initialBaseAmount: Double = 10
        let viewModel = CurrencyListViewModelNoTimer(service: mockedService, initialBaseAmount: initialBaseAmount)
        var valuesHash: [Double: Bool] = [:]
        var AUD_userInputAmout: [Double] = [23, 2.1, 124, 1]
        var ZAR_valuesExpectedHash: [Double: Bool] = [
            (initialBaseAmount * currenciesMock[0].rate): true,
            ((AUD_userInputAmout[0] / currenciesMock[3].rate) * currenciesMock[0].rate): true,
            ((AUD_userInputAmout[1] / currenciesMock[3].rate) * currenciesMock[0].rate): true,
            ((AUD_userInputAmout[2] / currenciesMock[3].rate) * currenciesMock[0].rate): true,
            ((AUD_userInputAmout[3] / currenciesMock[3].rate) * currenciesMock[0].rate): true,]
        
        dataSource = CurrencyListDataSource(viewModel: viewModel, dataReload: {
            let count = dataSource.tableView(self.tableView, numberOfRowsInSection: 0)
            XCTAssert(count == currenciesMock.count) // verify total number
            let cell = dataSource.tableView(self.tableView, cellForRowAt: IndexPath(row: 3, section: 0))
            let cellViewModel = dataSource.viewModels[0] // check ZAR updating its value while user edits AUD
            if let cell = cell as? CurrencyCell {
                cellViewModel.amountValue.then({ (value) in
                    valuesHash[value] = true
                    if valuesHash.keys.count == AUD_userInputAmout.count + 1 {
                        valuesHash.keys.forEach({ (key) in
                            XCTAssert(ZAR_valuesExpectedHash[key] == true)
                        })
                        expectation.fulfill()
                    }
                })
                AUD_userInputAmout.forEach { cell.didUpdateAmount?($0) }
            } else {
                XCTFail("Wrong cell, not a CurrencyCell")
            }
        }) { (_) in
        }
        dataSource.load { (error) in
            XCTAssertNil(error)
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
