//
//  BackgroundTimer.swift
//  RevolutCurrencyConverter
//
//  Created by Dmytro Kabyshev on 21/01/2019.
//  Copyright © 2019 Dmytro Kabyshev. All rights reserved.
//

import Foundation

/// Utility enum that helps represents TimeInterval interval
///
/// - minutes: value in minutes
/// - seconds: value in seconds
/// - hours: value in hours
enum EveryTimeFrame {
    case minutes(Int)
    case seconds(Int)
    case hours(Int)
    
    /// Convert to TimeInterval (in seconds)
    var interval: TimeInterval {
        switch self {
        case let .minutes(val): return TimeInterval(val * 60)
        case let .seconds(val): return TimeInterval(val)
        case let .hours(val): return TimeInterval(val * 3600)
        }
    }
}

/// Timer's states
///
/// - suspended: timer is not running
/// - resumed: timer is running
private enum State {
    case suspended
    case resumed
}

/// Background execution timer via DispatchSourceTimer
class BackgroundTimer {
    /// Timer interval in soconds
    private let timeInterval: TimeInterval
    /// Main timer `DispatchSourceTimer`
    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + self.timeInterval,
                       repeating: self.timeInterval)
        timer.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return timer
    }()
    /// Closure that will be triggered each `timeInterval`
    private var eventHandler: (() -> Void)?
    /// Current timer's state
    private var state: State = .suspended
    
    /// Create new background timer
    ///
    /// - Parameters:
    ///   - timeInterval: time interval for callaback `EveryTimeFrame`
    ///   - eventHandler: closure to run on interval basis
    init(timeInterval: EveryTimeFrame, eventHandler: @escaping (() -> Void)) {
        self.eventHandler = eventHandler
        self.timeInterval = timeInterval.interval
    }
    
    /// Resume (or start for a new one) the timer
    func resume() {
        guard state != .resumed else { return }
        state = .resumed
        timer.resume()
    }
    
    // Suspend running timer
    func suspend() {
        guard state != .suspended else { return }
        state = .suspended
        timer.suspend()
    }
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here
         https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
}
