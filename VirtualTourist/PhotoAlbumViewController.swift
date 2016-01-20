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

protocol PhotoAlbumViewControllerDelegate{
    func performDownload(coordinates: CLLocationCoordinate2D, page: String?)
}

class PhotoAlbumViewController: UIViewController,NSFetchedResultsControllerDelegate {
    
    var location: CLLocationCoordinate2D?
    var delegate: PhotoAlbumViewControllerDelegate?
    var context: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    typealias ClosureType = () -> ()
    var collectionUpdates: [ClosureType]!
    
    var sharedContext:NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController:NSFetchedResultsController = {
        var fetchRequest = NSFetchRequest(entityName: "Photo")
        let lat = (self.location!.latitude as Double).description
        let lon = (self.location!.longitude as Double).description
        let predicate = NSPredicate(format: "pin.latitude == %@ && pin.longitude == %@", lat,lon)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let fetchedResultesController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultesController
    }()

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    @IBAction func didPressNewCollection(sender: AnyObject) {
        delegate?.performDownload(location!, page: "1")
        if let pictures = fetchedResultsController.fetchedObjects as? [Photo] {
            for picture in pictures{
                context.deleteObject(picture)
            }
            CoreDataStack.sharedInstance().saveContext()
            delegate?.performDownload(location!, page: "1")
            
            //Get new photos
//            if let location = location {
//                //Get random page num from 2-4
//                let randomUInt = (arc4random() % 3)
//                switch randomUInt{
//                case UInt32(0):
////                    delegate?.perfor
//                }
//            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setMap()
        collectionView.dataSource = self
        collectionView.delegate = self
        do {
            try fetchedResultsController.performFetch()
        }catch let error as NSError{
            print("error: \(error)")
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        if fetchedResultsController.delegate == nil {
            fetchedResultsController.delegate = self
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        fetchedResultsController.delegate = nil
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
    
    //MARK: - NSFetchedResultsController Delegate Methods
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        collectionUpdates = [ClosureType]()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({ () -> Void in
            for updateBlock in self.collectionUpdates{
                updateBlock()
            }
            }, completion: nil)
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            collectionUpdates.append({
                self.collectionView.insertItemsAtIndexPaths([newIndexPath!])
            })
        case .Delete:
            collectionUpdates.append({
                self.collectionView.deleteItemsAtIndexPaths([newIndexPath!])
            })
        case .Update:
            collectionUpdates.append({
                self.collectionView.reloadItemsAtIndexPaths([newIndexPath!])
            })
        default:
            return
        }
    }
    

}

extension PhotoAlbumViewController:UICollectionViewDataSource,UICollectionViewDelegate{
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionCell", forIndexPath: indexPath) as! PhotoCollectionView
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    
}
