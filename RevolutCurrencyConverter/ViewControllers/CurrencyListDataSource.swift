//
//  CurrencyListDataSource.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import UIKit

/// DataSource for currencies list
final class CurrencyListDataSource: NSObject, UITableViewDataSource {
    private var viewModel: CurrencyListViewModelInterface
    fileprivate(set) var viewModels: [CurrencyViewModelInterface] = []
    private var dataReload: () -> Void
    private var onError: (Error) -> Void
    
    init(
        viewModel: CurrencyListViewModelInterface,
        dataReload: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.viewModel = viewModel
        self.dataReload = dataReload
        self.onError = onError
    }

    /// Load data through viewModel and propagate the update via `onDone` callback
    ///
    /// - Parameter onDone: callback to be called once loading is done
    func load(_ onDone: @escaping (Error?) -> Void) {
        viewModel.fetch()
            .then(on: .main) { [weak self] (viewModels) in
                self?.viewModels = viewModels
                onDone(nil)
                self?.dataReload()
                self?.viewModel.scheduleUpdate(every: .seconds(1))
            }.error(onDone)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell: CurrencyCell =  tableView.dequeueReusableCell(withIdentifier: CurrencyCell.reuseIdentifier, for: indexPath) as? CurrencyCell {
            let currencyViewModel = self.viewModels[indexPath.row]
            cell.viewModel = currencyViewModel
            cell.cellDidBecomeFirstResponder = { [weak self, weak tableView, weak currencyViewModel] in
                guard let viewModel = currencyViewModel,
                    let index = self?.viewModels.index(where: { $0.id == viewModel.id }) else { return }
                // Move selected item to the top
                tableView?.performBatchUpdates({
                    self?.viewModels.remove(at: index)
                    self?.viewModels.insert(viewModel, at: 0)
                    tableView?.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: 0, section: 0))
                }, completion: nil)
                tableView?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
            cell.didUpdateAmount = { [weak self, weak currencyViewModel] amount in
                do { try currencyViewModel?.updateCurrencyValue(amount: amount) }
                catch { self?.onError(error) }
            }
            return cell
        }
        
        return UITableViewCell()
    }
}
