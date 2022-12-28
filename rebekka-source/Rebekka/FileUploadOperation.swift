//
//  FileUploadOperation.swift
//  Rebekka
//
//  Created by Constantine Fry on 25/05/15.
//  Copyright (c) 2015 Constantine Fry. All rights reserved.
//

import Foundation

/// Operation for file uploading.
class FileUploadOperation: WriteStreamOperation {
    
    private var fileHandle: FileHandle?
    var fileURL: URL!
    
    override func start() {
        do {
            fileHandle = try FileHandle(forReadingFrom: fileURL)
            startOperationWithStream(writeStream)
        } catch let _error as NSError {
            error = _error
            fileHandle = nil
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
    }
    
    override func streamEventHasSpace(_ aStream: Stream) -> StreamOperation.Result {
        guard let writeStream = aStream as? OutputStream,
              let offsetInFile = fileHandle?.offsetInFile,
              let data = fileHandle?.readData(ofLength: 1024)
        else {
            return (false, nil)
        }
        
        let bytes = [UInt8](data)
        let count = bytes.count
        
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        pointer.initialize(from: bytes, count: count)
        
        let writtenBytes = writeStream.write(pointer, maxLength: count)
        pointer.deallocate()
        
        guard writtenBytes > 0 else {
            finishOperation()
            return (true, nil)
        }
        
        fileHandle?.seek(toFileOffset: offsetInFile + UInt64(writtenBytes))
        return (true, nil)
    }
}
