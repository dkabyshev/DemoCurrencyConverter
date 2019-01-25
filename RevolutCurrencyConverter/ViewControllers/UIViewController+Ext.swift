//
//  UIViewController+Ext.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 24/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import UIKit

typealias AlertCallback = (UIAlertAction) -> Void

extension UIAlertController {
    static func genericErrorAlertController(message: String? = nil,
                                            retryCallback: (AlertCallback)? = nil) -> UIAlertController {
        let defMessage = "Something went wrong, please try again".localized()
        let alertController = UIAlertController(title: "Error".localized(),
                                                message: message ?? defMessage,
                                                preferredStyle: .alert)
        let action = UIAlertAction(title: "OK".localized(),
                                   style: .cancel,
                                   handler: nil)
        alertController.addAction(action)
        if let retryCallback = retryCallback {
            let retry = UIAlertAction(title: "Retry".localized(),
                                      style: .default,
                                      handler: retryCallback)
            alertController.addAction(retry)
        }
        return alertController
    }
}


extension UIViewController {
    func showDefaultError(error: Error? = nil, retry: AlertCallback? = nil) {
        let error = UIAlertController.genericErrorAlertController(message: error?.localizedDescription,
                                                                  retryCallback: retry)
        self.present(error, animated: true, completion: nil)
    }
}
