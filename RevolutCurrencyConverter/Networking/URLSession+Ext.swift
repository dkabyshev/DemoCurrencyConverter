//
//  URLSession+Ext.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

/// Protocol to abstract from URLSession
protocol NetworkingSession {
    func request(_ router: NetworkRouter) -> Promise<Data>
}

extension URLSession: NetworkingSession {
    /// Execute request described by `router` and returns a `Promise`
    ///
    /// - Parameter router: `NetworkRouter` describing the request
    /// - Returns: promise that will be fulfiled once data is fetched
    func request(_ router: NetworkRouter) -> Promise<Data> {
        // Start by constructing a Promise, that will later returned
        // Internal task of such promise is out network operation
        let promise = Promise<Data>() { promise in
            let request = try router.asURLRequest()
            let task = self.dataTask(with: request) { data, _, error in
                // Reject or resolve the promise, depending on the result
                if let error = error {
                    promise.reject(error)
                } else {
                    promise.resolve(data ?? Data())
                }
            }
            task.resume()
        }
        return promise
    }
}
