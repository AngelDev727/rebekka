//
//  ResourceListOperation.swift
//  Rebekka
//
//  Created by Constantine Fry on 25/05/15.
//  Copyright (c) 2015 Constantine Fry. All rights reserved.
//

import Foundation

/* Resource type, values defined in `sys/dirent.h`. */
public enum ResourceType: String {
    case Unknown        = "Unknown"        // DT_UNKNOWN
    case Directory      = "Directory"      // DT_DIR
    case RegularFile    = "RegularFile"    // DT_REG
    case SymbolicLink   = "SymbolicLink"   // DT_LNK
    
    case NamedPipe          = "NamedPipe"          // DT_FIFO
    case CharacterDevice    = "CharacterDevice"    // DT_CHR
    case BlockDevice        = "BlockDevice"        // DT_BLK
    case LocalDomainSocket  = "LocalDomainSocket"  // DT_SOCK
    case Whiteout           = "Whiteout"           // DT_WHT
}

public class ResourceItem: CustomStringConvertible {
    public var type: ResourceType = .Unknown
    public var name: String = ""
    public var link: String = ""
    public var date: Date = Date()
    public var size: Int = 0
    public var mode: Int = 0
    public var owner: String = ""
    public var group: String = ""
    public var path: String = "/"
    
    public var description: String {
        get {
            return "\nResourceItem: \(name), \(type.rawValue)"
        }
    }
}


private let _resourceTypeMap: [Int:ResourceType] = [
    Int(DT_UNKNOWN): ResourceType.Unknown,
    Int(DT_FIFO):    ResourceType.NamedPipe,
    Int(DT_SOCK):    ResourceType.LocalDomainSocket,
    Int(DT_CHR): ResourceType.CharacterDevice,
    Int(DT_DIR): ResourceType.Directory,
    Int(DT_BLK): ResourceType.BlockDevice,
    Int(DT_REG): ResourceType.RegularFile,
    Int(DT_LNK): ResourceType.SymbolicLink,
    Int(DT_WHT): ResourceType.Whiteout
]

/// Operation for resource listing.
class ResourceListOperation: ReadStreamOperation {
    
    private var inputData: Data?
    var resources: [ResourceItem]?
    
    override func streamEventEnd(_ aStream: Stream) -> StreamOperation.Result {
        guard let inputData = inputData else {
            return (false, nil)
        }
        
        var offset = 0
        
        let bytes = [UInt8](inputData)
        let count = bytes.count
        
        let total = CFIndex(inputData.count)
        var parsed = CFIndex(0)
        
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        pointer.initialize(from: bytes, count: count)
        
        let entity = UnsafeMutablePointer<Unmanaged<CFDictionary>?>.allocate(capacity: 1)
        var _resources = [ResourceItem]()
        
        repeat {
            parsed = CFFTPCreateParsedResourceListing(nil, pointer.advanced(by: offset), total - offset, entity)
            
            if parsed > 0 {
                offset += parsed
                if let value = entity.pointee?.takeUnretainedValue() {
                    _resources.append(mapFTPResources(value))
                }
            }
        } while (parsed > 0)
        
        resources = _resources
        
        pointer.deallocate()
        entity.deallocate()
        
        return (true, nil)
    }
    
    private func mapFTPResources(_ resources: NSDictionary) -> ResourceItem {
        
        func extract<T>(_ key: CFString, default value: T) -> T {
            return resources[key as String] as? T ?? value
        }
        
        let item = ResourceItem()
        item.mode  = extract(kCFFTPResourceMode, default: 0)
        item.owner = extract(kCFFTPResourceOwner, default: "")
        item.group = extract(kCFFTPResourceGroup, default: "")
        item.link  = extract(kCFFTPResourceLink, default: "")
        item.size  = extract(kCFFTPResourceSize, default: 0)
        item.date  = extract(kCFFTPResourceModDate, default: Date())
        
        // CFFTPCreateParsedResourceListing assumes that teh names are in MacRoman.
        // To fix it we create data from string and read it with correct encoding.
        // https://devforums.apple.com/message/155626#155626
        let name = extract(kCFFTPResourceName, default: "")
        if configuration.encoding == String.Encoding.macOSRoman {
            item.name = name
        } else if let data = name.data(using: String.Encoding.macOSRoman),
                  let encoded = String(data: data, encoding: configuration.encoding)
        {
            item.name = encoded
        }
        
        if let path = path, !item.name.isEmpty {
            item.path = path + item.name
        }
        
        let type = extract(kCFFTPResourceType, default: 0)
        if let resourceType = _resourceTypeMap[type] {
            item.type = resourceType
        }
        
        return item
    }
    
    override func streamEventHasBytes(_ aStream: Stream) -> StreamOperation.Result {
        guard let inputStream = aStream as? InputStream else {
            return (false, nil)
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        let result = inputStream.read(buffer, maxLength: 1024)
        
        if result > 0 {
            if inputData == nil {
                inputData = Data(bytes: buffer, count: result)
            } else {
                inputData?.append(buffer, count: result)
            }
        }
        
        buffer.deallocate()
        return (true, nil)
    }
    
}
