//
//  CurrencyRouter.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

enum CurrenciesBase: String {
    case eur = "EUR"
}

enum CurrencyRouterErrors: Error {
    case urlNotValid
}

enum CurrencyRouter: NetworkRouter {
    case currencies(base: CurrenciesBase)
    
    var method: HTTPMethod {
        switch self {
        case .currencies:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .currencies: return "/latest"
        }
    }
    
    var queryParameters: [URLQueryItem]? {
        switch self {
        case let .currencies(base):
            return [URLQueryItem(name: "base", value: base.rawValue)]
        }
    }
    
    // MARK: URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: "https://revolut.duckdns.org".appending(self.path)) else {
            throw CurrencyRouterErrors.urlNotValid
        }
        urlComponents.queryItems = self.queryParameters
        guard let url = urlComponents.url else {
            throw CurrencyRouterErrors.urlNotValid
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        return urlRequest
    }
}
