//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by zhangyunchen on 16/1/18.
//  Copyright © 2016年 zhangyunchen. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    var location: CLLocationCoordinate2D?
    
    var sharedContext:NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController:NSFetchedResultsController = {
        var fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let fetchedResultesController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultesController
    }()

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMap()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func setMap(){
        if let location = location {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            mapView.addAnnotation(annotation)
            let cammera =
            MKMapCamera(lookingAtCenterCoordinate: location, fromEyeCoordinate: location, eyeAltitude: 100000)
            mapView.setCamera(cammera, animated: true)
        }
        
    }

}
