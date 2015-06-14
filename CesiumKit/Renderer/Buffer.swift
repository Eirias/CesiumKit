//
//  Buffer.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 26/05/2015.
//  Copyright (c) 2015 Test Toast. All rights reserved.
//

import Metal

class Buffer {
    
    let metalBuffer: MTLBuffer
    
    var componentDatatype: ComponentDatatype
    
    var data: UnsafeMutablePointer<Void> {
        return metalBuffer.contents()
    }
    
    var length: Int {
        return metalBuffer.length
    }
    
    init (device: MTLDevice, array: UnsafePointer<Void> = nil, componentDatatype: ComponentDatatype, sizeInBytes: Int) {
        
        assert(sizeInBytes > 0, "bufferSize must be greater than zero")
        
        if array != nil {
            metalBuffer = device.newBufferWithBytes(array, length: sizeInBytes, options: nil)
        } else {
            metalBuffer = device.newBufferWithLength(sizeInBytes, options: nil)
        }
        
        self.componentDatatype = componentDatatype
    }
    
}