//
//  QueueManager.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 1/01/2016.
//  Copyright © 2016 Test Toast. All rights reserved.
//

import Foundation

private let _maxConcurrentNetworkRequests = 12

class QueueManager {
    
    static let sharedInstance = QueueManager()
    
    let processorQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = .utility
        return queue
    }
    
    let networkQueue = {
        let queue = NSOperationQueue()
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = _maxConcurrentNetworkRequests
        return queue
    }

}