//
//  CollectionViewAndMapViewController.swift
//  VirtualTourist
//
//  Created by Yash Rao on 2/24/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData


class CollectionViewAndMapViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataController: DataController!
    var selectedPinCoords: CLLocationCoordinate2D!
    var selectedPin: Pin?
    var photoArray: [Photo] = []
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        collectionView.delegate = self
    }
    
    
    
    
    
    func fetchedResultsControllerAndPhotoArray() -> [Photo]? {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: (dataController?.persistentContainer.viewContext)!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch cannot be completed: \(error.localizedDescription)")
        }
        
        do {
            let numberPhotos = try fetchedResultsController.managedObjectContext.count(for: fetchRequest)
            for index in 0..<numberPhotos {
                photoArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)))
            }
            return photoArray
        } catch {
            return nil
        }
    }
}
