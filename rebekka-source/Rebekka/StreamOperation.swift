//
//  StreamOperation.swift
//  Rebekka
//
//  Created by Constantine Fry on 25/05/15.
//  Copyright (c) 2015 Constantine Fry. All rights reserved.
//

import Foundation

/// The base class for stream operations.
class StreamOperation: BaseOperation, StreamDelegate {
    
    typealias Result = (Bool, Error?)
    private var currentStream: Stream?
    
    let queue: DispatchQueue
    var path: String?
    
    var fullURL: URL? {
        if let path = path {
            return configuration.url?.appendingPathComponent(path)
        } else {
            return configuration.url
        }
    }
    
    init(configuration: SessionConfiguration, queue: DispatchQueue) {
        self.queue = queue
        super.init(configuration: configuration)
    }
    
    @objc func stream(_ aStream: Stream, handle event: Stream.Event) {
        guard !isCancelled else {
            streamEventError(aStream)
            error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
            finishOperation()
            return
        }
        
        switch event {
        case .openCompleted:
            streamEventOpenComleted(aStream)
        case .hasBytesAvailable:
            streamEventHasBytes(aStream)
        case .hasSpaceAvailable:
            streamEventHasSpace(aStream)
        case .errorOccurred:
            streamEventError(aStream)
            finishOperation()
        case .endEncountered:
            streamEventEnd(aStream)
            finishOperation()
        default:
            print("Unkonwn NSStreamEvent: \(event)")
        }
    }
    
    func startOperationWithStream(_ aStream: Stream) {
        currentStream = aStream
        configureStream(stream: aStream)
        
        currentStream?.open()
        state = .executing
    }
    
    func finishOperation() {
        currentStream?.close()
        currentStream = nil
        state = .finished
    }
    
    @discardableResult
    func streamEventOpenComleted(_ aStream: Stream) -> Result {
        return (true, nil)
    }
    
    @discardableResult
    func streamEventEnd(_ aStream: Stream) -> Result {
        return (true, nil)
    }
    
    @discardableResult
    func streamEventHasBytes(_ aStream: Stream) -> Result {
        return (true, nil)
    }
    
    @discardableResult
    func streamEventHasSpace(_ aStream: Stream) -> Result {
        return (true, nil)
    }
    
    func streamEventError(_ aStream: Stream) {
        error = aStream.streamError
    }
}

private extension StreamOperation {
    
    func configureStream(stream: Stream) {
        stream.setProperty(true, forKey: Stream.PropertyKey(rawValue: kCFStreamPropertyShouldCloseNativeSocket as String))
        stream.setProperty(true, forKey: Stream.PropertyKey(rawValue: kCFStreamPropertyFTPFetchResourceInfo as String))
        stream.setProperty(configuration.passive, forKey: Stream.PropertyKey(rawValue: kCFStreamPropertyFTPUsePassiveMode as String))
        stream.setProperty(configuration.username, forKey: Stream.PropertyKey(rawValue: kCFStreamPropertyFTPUserName as String))
        stream.setProperty(configuration.password, forKey: Stream.PropertyKey(rawValue: kCFStreamPropertyFTPPassword as String))
        stream.delegate = self
    }
}
