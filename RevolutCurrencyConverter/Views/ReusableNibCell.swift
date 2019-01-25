//
//  ReusableNibCell.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import UIKit

protocol ReusableNibCell: class {
    /// The reuse identifier to use when registering and later dequeuing a reusable cell
    static var reuseIdentifier: String { get }
    
    /// The nib file to use to load a new instance of the View designed in a XIB
    static var nib: UINib { get }
}

// MARK: - Default implementation
extension ReusableNibCell {
    /// By default, use the name of the class as String for its reuseIdentifier
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
    /// By default, use the nib which have the same name as the name of the class,
    /// and located in the bundle of that class
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
}

extension UITableView {
    /**
     Register a NIB-Based `UITableViewCell` subclass (conforming to `ReusableNibCell`)
     - parameter cellType: the `UITableViewCell` (`ReusableNibCell`-conforming) subclass to register
     - seealso: `register(_:,forCellReuseIdentifier:)`
     */
    final func register<T: ReusableNibCell>(cellType: T.Type) {
        self.register(cellType.nib, forCellReuseIdentifier: cellType.reuseIdentifier)
    }
}
