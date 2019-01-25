//
//  Result.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

/// Wrapper around result value (Success or Fialure)
///
/// - success: success with result value of type `Value`
/// - failure: failure with `Error`
enum Result<Value> {
    case success(Value)
    case failure(Error)
    
    var value: Value? {
        switch self {
        case let .success(value): return value
        default: return nil
        }
    }
}
