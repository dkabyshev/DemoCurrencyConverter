//
//  DispatchQueue+Ex.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 20/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

enum DispatchQueueType {
    case main
    case userInitiated
    case background
    
    var dispatchQueue: DispatchQueue {
        switch self {
        case .main: return DispatchQueue.main
        case .background: return DispatchQueue.global(qos: .background)
        case .userInitiated: return DispatchQueue.global(qos: .userInitiated)
        }
    }
}
