//
//  WriteStreamOperation.swift
//  Rebekka
//
//  Created by Constantine Fry on 25/05/15.
//  Copyright (c) 2015 Constantine Fry. All rights reserved.
//

import Foundation

/// The base class for write stream operatons.
class WriteStreamOperation: StreamOperation {
    
    lazy var writeStream: OutputStream = {
        guard let url = fullURL else {
            return OutputStream()
        }
        
        let cfStream = CFWriteStreamCreateWithFTPURL(nil, url as CFURL)
        CFWriteStreamSetDispatchQueue(cfStream.takeUnretainedValue(), queue)
        return cfStream.takeRetainedValue()
    }()
    
    override func start() {
        startOperationWithStream(writeStream)
    }
}
