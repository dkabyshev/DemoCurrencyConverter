//
//  ViewController.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 20/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import UIKit

class CurrencyListViewController: UITableViewController {
    private var dataSource: CurrencyListDataSource!
    private weak var activity: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = CurrencyListDataSource(viewModel: CurrencyListViewModel(service: CurrencyService()), dataReload: {[weak self] in
            self?.tableView.reloadData()
        }) {[weak self] error in
            self?.showDefaultError(error: error)
        }
        tableView.register(cellType: CurrencyCell.self)
        tableView.dataSource = dataSource
        tableView.tableFooterView = UIView()

        let activity = UIActivityIndicatorView(style: .gray)
        view.addSubview(activity)
        activity.center = view.center
        activity.hidesWhenStopped = true
        self.activity = activity
        self.load()
    }
    
    private func load() {
        activity?.startAnimating()
        
        dataSource.load { [weak self] error in
            self?.activity?.stopAnimating()
            if let _ = error {
                self?.showDefaultError() { [weak self] _ in
                    // Retry
                    self?.load()
                }
            }
        }
    }
}
