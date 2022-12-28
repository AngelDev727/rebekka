//
//  FileDownloadOperation.swift
//  Rebekka
//
//  Created by Constantine Fry on 25/05/15.
//  Copyright (c) 2015 Constantine Fry. All rights reserved.
//

import Foundation

/// Operation for downloading a file from FTP server.
class FileDownloadOperation: ReadStreamOperation {
    
    private var fileHandle: FileHandle?
    var fileURL: URL?
    
    override func start() {
        guard let _fileURL = URL(string: NSTemporaryDirectory())?.appendingPathComponent(NSUUID().uuidString) else {
            return
        }
        
        fileURL = _fileURL
        
        do {
            try Data().write(to: _fileURL, options: .atomicWrite)
            fileHandle = try FileHandle(forWritingTo: _fileURL)
            startOperationWithStream(readStream)
        } catch let _error as NSError {
            error = _error
            finishOperation()
        }
    }
    
    override func streamEventEnd(_ aStream: Stream) -> StreamOperation.Result {
        fileHandle?.closeFile()
        return (true, nil)
    }
    
    override func streamEventError(_ aStream: Stream) {
        super.streamEventError(aStream)
        fileHandle?.closeFile()
        
        guard let _fileURL = fileURL else {
            return
        }
        
        try? FileManager.default.removeItem(at: _fileURL)
        fileURL = nil
    }
    
    override func streamEventHasBytes(_ aStream: Stream) -> StreamOperation.Result {
        guard let inputStream = aStream as? InputStream else {
            return (false, nil)
        }
        
        var parsetBytes: Int = 0
        
        repeat {
            parsetBytes = inputStream.read(temporaryBuffer, maxLength: 1024)
            if parsetBytes > 0 {
                autoreleasepool {
                    fileHandle?.write(Data(bytes: temporaryBuffer, count: parsetBytes))
                }
            }
        } while (parsetBytes > 0)
        
        return (true, nil)
    }
}
