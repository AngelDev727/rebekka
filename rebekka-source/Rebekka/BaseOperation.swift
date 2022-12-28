//
//  BaseOperation.swift
//  Rebekka
//
//  Created by Constantine Fry on 25/05/15.
//  Copyright (c) 2015 Constantine Fry. All rights reserved.
//

import Foundation

enum OperationState {
    case none
    case ready
    case executing
    case finished
}

/// The base class for FTP operations used in framework.
class BaseOperation: Operation {

    var error: Error?
    let configuration: SessionConfiguration
    
    var state = OperationState.ready {
        willSet {
            willChangeValue(forKey: "isReady")
            willChangeValue(forKey: "isExecuting")
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isReady")
            didChangeValue(forKey: "isExecuting")
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isAsynchronous: Bool {
        true
    }
    
    override var isReady: Bool {
        state == .ready
    }
    
    override var isExecuting: Bool {
        state == .executing
    }
    
    override var isFinished: Bool {
        state == .finished
    }
    
    init(configuration: SessionConfiguration) {
        self.configuration = configuration
    }
}
