//
//  Router.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

/// Represents common HTTP methods to use with request
enum HTTPMethod: String {
    case get
    case post
    case put
    case patch
    case delete
}

/// Generic NetworkRouter that represents request
protocol NetworkRouter {
    
    /// Returns a URL request or throws if an `Error` was encountered.
    ///
    /// - throws: An `Error` if the underlying `URLRequest` is `nil`.
    ///
    /// - returns: A URL request.
    func asURLRequest() throws -> URLRequest
}
