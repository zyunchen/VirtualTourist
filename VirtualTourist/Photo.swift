//
//  Photo.swift
//  VirtualTourist
//
//  Created by zhangyunchen on 16/1/18.
//  Copyright © 2016年 zhangyunchen. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    
    @NSManaged var url: String
    @NSManaged var text: String
    @NSManaged var id: String
    @NSManaged var pin: Pin
    @NSManaged var saved: NSNumber
    
    //MARK: - Helper Methods
    
    func getImage() -> UIImage? {
        let path = getPath()
        let pathArray = [path,"\(id)"]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        let fileManager = NSFileManager()
        
        if fileManager.fileExistsAtPath(filePath!.path!) == false{
            return UIImage(named: "imageHolder")
        } else{
            return UIImage(data: NSData(contentsOfURL: filePath!)!)
        }
    }
    
    func getPath() -> String{
        let directory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let dirPath = directory[0]
        return dirPath
    }
    
    func isExisted() -> Bool{
        let path = getPath()
        let pathArray = [path, "\(id)"]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        let fileManager = NSFileManager()
        return fileManager.fileExistsAtPath(filePath!.path!)
    }
    
    //MARK : Deletion
    
    override func prepareForDeletion() {
        let fileManager = NSFileManager.defaultManager()
        let dirPath = getPath()
        _ = try? fileManager.removeItemAtPath("\(dirPath)/\(id)")
    }
    
}
