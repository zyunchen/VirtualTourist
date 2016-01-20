//
//  Photo.swift
//  VirtualTourist
//
//  Created by zhangyunchen on 16/1/18.
//  Copyright © 2016年 zhangyunchen. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {
    
    @NSManaged var url: String
    @NSManaged var text: String
    @NSManaged var id: String
    @NSManaged var pin: Pin
    @NSManaged var saved: NSNumber
}
