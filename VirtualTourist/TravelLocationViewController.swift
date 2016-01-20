//
//  ViewController.swift
//  VirtualTourist
//
//  Created by zhangyunchen on 16/1/18.
//  Copyright © 2016年 zhangyunchen. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationViewController: UIViewController,MKMapViewDelegate {
    
    let Map_Position = "mapPosition"
    

    var sharedContext:NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMapPosition()
        loadPins()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressAndHoldMap(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            let touchPosition = sender.locationInView(mapView)
            let mapCoordinate = mapView.convertPoint(touchPosition, toCoordinateFromView: mapView)
            addAnnotation(mapCoordinate)
        }
        
    }
    

    
    //get saved Position, and set it, if can not get , do nothing.
    func setMapPosition(){
        if let mapPosition = NSUserDefaults.standardUserDefaults().objectForKey(Map_Position) as? [String: AnyObject]{
            let lat = mapPosition["latitude"] as! CLLocationDegrees
            let lon = mapPosition["longitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let lonDelta = mapPosition["latitudeDelta"] as! CLLocationDegrees
            let latDelta = mapPosition["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let mapRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(mapRegion, animated: true)
        }
    }
    
    
    //Save map position
    func savePosition(){
        let mapPosition: [String: AnyObject] = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        NSUserDefaults.standardUserDefaults().setObject(mapPosition, forKey: Map_Position)
    }
    
    
    func loadPins(){
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: sharedContext)
        fetchRequest.entity = entityDescription
        
//        let fetchedObjects:[AnyObject]?
//        fetchedObjects = try? sharedContext.executeFetchRequest(fetchRequest)
//        
//        print(fetchedObjects)
//        
//        let pins = fetchedObjects as? [Pin]
//        
//        print(pins?.count)
        
        let pins: [Pin]
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            print (results)
            pins = results as! [Pin]
        }catch {
            pins = [Pin]()
        }
        
        
//        if let fetchedObjects = pins {
            let currentAnnotions = mapView.annotations
            mapView.removeAnnotations(currentAnnotions)
            for pin in pins {
                let lat = (pin.latitude as NSString).doubleValue
                let lon = (pin.longitude as NSString).doubleValue
                addAnnotation(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
//        }

    }
    
    func addAnnotation(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        annotation.title = "Visited"
        mapView.addAnnotation(annotation)
        
        //save to coreData
        let pinEntity =
        NSEntityDescription.entityForName("Pin", inManagedObjectContext: sharedContext)
        let pin =
        Pin(entity: pinEntity!, insertIntoManagedObjectContext: sharedContext)
        pin.latitude = "\(coordinates.latitude)"
        pin.longitude = "\(coordinates.longitude)"
        pin.date = NSDate()
//        pin.photos = [Photo]()
        
        CoreDataStack.sharedInstance().saveContext()

        
        
    }
    
    //MARK: - MKMapViewDelegate Methods
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        savePosition()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("annotation") as? MKPinAnnotationView{
            pinView.annotation = annotation
            return pinView
        }else{
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
            pinView.canShowCallout = true
            pinView.pinTintColor = UIColor.redColor()
            pinView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            return pinView
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("press pin")
        performSegueWithIdentifier("showPhotos", sender: view.annotation)
    }
    
    //MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhotos" {
            let albumController = segue.destinationViewController as! PhotoAlbumViewController
//            albumController.context =  coreDataStack.context
            albumController.location = (sender as? MKAnnotation)?.coordinate
//            albumController.imageDownloadQueue = imageDownloadQueue
//            albumController.delegate = self
        }
    }


}

