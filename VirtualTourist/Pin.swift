//
//  Pin.swift
//  VirtualTourist
//
//  Created by zhangyunchen on 16/1/18.
//  Copyright © 2016年 zhangyunchen. All rights reserved.
//

import Foundation
import CoreData

class Pin:NSManagedObject{
    
    @NSManaged var latitude:String
    @NSManaged var longitude:String
    @NSManaged var photos:[Photo]
    @NSManaged var date:NSDate
}
