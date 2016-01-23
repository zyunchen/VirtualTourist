//
//  ImageDownloadQueue.swift
//  VirtualTourist
//
//  Created by zhangyunchen on 16/1/22.
//  Copyright © 2016年 zhangyunchen. All rights reserved.
//

import Foundation

class ImageDownloadQueue {
    
    lazy var pendingOperations = [NSString:NSOperation]()
    
    lazy var downloadQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "ImageDownloadQueue"
        return queue
    }()
}
