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

class TravelLocationViewController: UIViewController,MKMapViewDelegate,PhotoAlbumViewControllerDelegate {
    
    let Map_Position = "mapPosition"
    var imageDownloadQueue: ImageDownloadQueue!

    var sharedContext:NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMapPosition()
        loadPins()
        imageDownloadQueue = ImageDownloadQueue()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressAndHoldMap(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            let touchPosition = sender.locationInView(mapView)
            let mapCoordinate = mapView.convertPoint(touchPosition, toCoordinateFromView: mapView)
            //save to coreData
            let pinEntity =
            NSEntityDescription.entityForName("Pin", inManagedObjectContext: sharedContext)
            let pin =
            Pin(entity: pinEntity!, insertIntoManagedObjectContext: sharedContext)
            pin.latitude = "\(mapCoordinate.latitude)"
            pin.longitude = "\(mapCoordinate.longitude)"
            pin.date = NSDate()
            
            CoreDataStack.sharedInstance().saveContext()
            
            addAnnotation(mapCoordinate)
            downloadImages(mapCoordinate, page: "1")
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
        
        let pins: [Pin]
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            print (results)
            pins = results as! [Pin]
        }catch {
            pins = [Pin]()
        }
        
        let currentAnnotions = mapView.annotations
        mapView.removeAnnotations(currentAnnotions)
        for pin in pins {
            let lat = (pin.latitude as NSString).doubleValue
            let lon = (pin.longitude as NSString).doubleValue
            addAnnotation(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
    }
    
    //MARK: - Download Methods
    
    func downloadImages(coordinates : CLLocationCoordinate2D, page: String?) {
        let client = FlickrHelper.sharedInstance
        client.getImagesWith(coordinates.latitude, longitude: coordinates.longitude, page: page){ (data, error) in
            if let errorMessage = error {
                print("Error: \(errorMessage)")
            } else {
                print(data?.description)
                self.saveImages(coordinates, data: data, error: error)
            }
        }
    }
    
    func saveImages(coordinates : CLLocationCoordinate2D, data: NSArray?, error: NSString? ) {
        guard let data = data else {
            print("data is nil")
            return
        }
        sharedContext.performBlock(){
            let fetchRequest = NSFetchRequest()
            let entityDescription = NSEntityDescription.entityForName("Pin", inManagedObjectContext: self.sharedContext)
            fetchRequest.entity = entityDescription
            let lat = (coordinates.latitude as Double).description
            let lon = (coordinates.longitude as Double).description
            let predicate = NSPredicate(format: "latitude == %@ && longitude == %@", lat,lon)
            fetchRequest.predicate = predicate
            
            let pins: [Pin]
            do {
                let results = try self.sharedContext.executeFetchRequest(fetchRequest)
                print (results)
                pins = results as! [Pin]
            }catch {
                pins = [Pin]()
            }
            
            var pin:Pin?
            print("it has been here and pins count is \(pins.count)")
            print("it can access pin's photo list \(pins[0].photos.count)")
            if pins.count > 0 {
                pin = pins[0]
            }else{
                let pinEntity =
                NSEntityDescription.entityForName("Pin", inManagedObjectContext: self.sharedContext)
                pin = Pin(entity: pinEntity!, insertIntoManagedObjectContext: self.sharedContext)
                pin!.latitude = "\(coordinates.latitude)"
                pin!.longitude = "\(coordinates.longitude)"
                pin!.date = NSDate()
            }

            let photoEntity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: self.sharedContext)
            
            for data in data {
                let photo = Photo(entity: photoEntity!, insertIntoManagedObjectContext: self.sharedContext)
                photo.url = data["url_m"] as! String
                photo.id = data["id"] as! String
                photo.pin = pin!
                photo.saved = false
//                photo.addObject(picture)
                do {
                    try self.sharedContext.save()
                    self.backgroundImageDownload(photo.objectID)
                } catch let error as NSError {
                    print("Error Saving Child Context: \(error.localizedDescription)")
                }
            }
            CoreDataStack.sharedInstance().saveContext()
        }
    }
    
    
    func addAnnotation(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        annotation.title = "Visited"
        mapView.addAnnotation(annotation)
    }
    
    func backgroundImageDownload(tempObjectId: NSManagedObjectID){
        sharedContext.performBlock { () -> Void in
            guard let photo = self.sharedContext.objectWithID(tempObjectId) as? Photo else{
                return
            }
            let id = photo.id
            let url = photo.url
            let imageDownloadOperation = ImageDownloadOperation(url: url, id: id)
            
            let isExisted = photo.isExisted()
            imageDownloadOperation.completionBlock = { () -> Void in
                if isExisted {
                    self.imageDownloadQueue.pendingOperations.removeValueForKey(id)
                    
                    self.sharedContext.performBlock(){ () -> Void in
                        photo.saved = true
                        do {
                            try self.sharedContext.save()
                            CoreDataStack.sharedInstance().saveContext()
                        } catch let error as NSError{
                            print(error.localizedDescription)
                        }
                    }
                }else{
                    self.sharedContext.performBlock({ () -> Void in
                        photo.saved = false
                        CoreDataStack.sharedInstance().saveContext()
                    })
                }
                
            }
            self.imageDownloadQueue.pendingOperations[id] = imageDownloadOperation
            self.imageDownloadQueue.downloadQueue.addOperation(imageDownloadOperation)
        }

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
            albumController.delegate = self
        }
    }
    
    //MARK: - PhotoAlbumViewControllerDelegate
    
    func performDownload(coordinates: CLLocationCoordinate2D, page: String?){
        downloadImages(coordinates, page: page)
    }


}

