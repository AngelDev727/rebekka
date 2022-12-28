//
//  ReadStreamOperation.swift
//  Rebekka
//
//  Created by Constantine Fry on 25/05/15.
//  Copyright (c) 2015 Constantine Fry. All rights reserved.
//

import Foundation

/// The base class for read stream operations.
class ReadStreamOperation: StreamOperation {
    
    lazy var temporaryBuffer: UnsafeMutablePointer<UInt8> = {
        return UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
    }()
    
    lazy var readStream: InputStream = {
        guard let url = fullURL else {
            return InputStream()
        }
        
        let cfStream = CFReadStreamCreateWithFTPURL(nil, url as CFURL)
        CFReadStreamSetDispatchQueue(cfStream.takeUnretainedValue(), self.queue)
        return cfStream.takeRetainedValue()
    }()
    
    override func start() {
        startOperationWithStream(readStream)
    }
}
