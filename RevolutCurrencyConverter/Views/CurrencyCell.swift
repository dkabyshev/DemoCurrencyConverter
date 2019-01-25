//
//  CurrencyCell.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import UIKit

class CurrencyCell: UITableViewCell, ReusableNibCell {
    @IBOutlet weak var currencyIcon: UIImageView!
    @IBOutlet weak var currencySymbol: UILabel!
    @IBOutlet weak var currencyName: UILabel!
    @IBOutlet weak var textInput: UITextField!
    let formatter = NumberFormatter()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textInput.delegate = self
        currencySymbol.text = ""
        currencyName.text = ""
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        currencyIcon.layer.cornerRadius = currencyIcon.bounds.width / 2
        currencyIcon.layer.masksToBounds = true
    }

    var didUpdateAmount: ((Double) -> Void)?
    var cellDidBecomeFirstResponder: (() -> Void)?
    var viewModel: CurrencyViewModelInterface! {
        didSet {
            guard viewModel != nil else { return }
            currencySymbol.text = viewModel.currencyCode
            currencyName.text = viewModel.currencyName
            currencyIcon.image = UIImage(named: viewModel.currencyCode.lowercased())
            viewModel.amountValue.then(on: .main) { [weak self] (value) in
                guard self?.textInput.isFirstResponder == false else { return }
                let newString = self?.formatter.string(from: NSNumber(value: value)) ?? "0"
                if self?.textInput.text != newString {
                     self?.textInput.text = newString
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currencySymbol.text = ""
        viewModel = nil
        cellDidBecomeFirstResponder = nil
    }
    
    @IBAction func editingDidChange(_ sender: Any) {
        didUpdateAmount?(Double(textInput.text ?? "") ?? 0)
    }
}

extension CurrencyCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = "\(formatter.number(from: textField.text ?? "0")?.doubleValue ?? 0)"
        cellDidBecomeFirstResponder?()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text ?? "") as NSString
        let candidateString = newString.replacingCharacters(in: range, with: string)
        return candidateString.isDouble(with: formatter, allowedDecimals: 2)
    }
}
