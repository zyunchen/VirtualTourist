//
//  ImageDownloadOperation.swift
//  VirtualTourist
//
//  Created by zhangyunchen on 16/1/21.
//  Copyright © 2016年 zhangyunchen. All rights reserved.
//

import Foundation

class ImageDownloadOperation: NSOperation {
    let url: String!
    let id: String!
    
    var dirPath: String {
        let documentsDirectiry = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return documentsDirectiry[0]
    }
    
    init(url: String,id: String) {
        self.url = url
        self.id = id
    }
    
    override func main() {
        if self.cancelled{
            print("operation canceld")
            return
        }
        
        let pathArray = [dirPath,"\(id)"]
        guard let imageDirectoryUrl = NSURL.fileURLWithPathComponents(pathArray),
            imageDirectoryPath = imageDirectoryUrl.path,
            webImageUrl = NSURL(string: url) else{
                return
        }
        
        let fileManager = NSFileManager()
        if !fileManager.fileExistsAtPath(imageDirectoryPath) {
            if let downloadImage = NSData(contentsOfURL: webImageUrl){
                downloadImage.writeToURL(imageDirectoryUrl, atomically: true)
            }
        }
        
    }
    
    
}
