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


class CollectionViewAndMapViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    //OUTLETS
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var reloadOrDeleteButton: UIButton!
    
    //VARIABLES
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataController: DataController!
    var selectedPinCoords: CLLocationCoordinate2D!
    var selectedPin: Pin!
    var coreDataPhotoArray: [Photo] = []
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var maxCellCount: Int = 21
    var currentlySelected: [Int] = []
    
    //Set up fetchedController and generate coreDataPhotoArray to populate Collection View using fetch request
    
    func fetchedResultsControllerAndPhotoArray() -> [Photo]? {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [selectedPin])
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: (dataController?.persistentContainer.viewContext)!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        var photoArray:[Photo] = []
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureMapView()
        configureUI()
        
        let storedPhotos = fetchedResultsControllerAndPhotoArray()
        if storedPhotos != nil && storedPhotos?.count != 0 {
            coreDataPhotoArray = storedPhotos!
            reloadCollectionView()
        } else {
            freshSearch()
        }
    }
    
    //Have mapView zoom in on location of pin
    
    func configureMapView() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = selectedPinCoords
        mapView.addAnnotation(annotation)
        self.mapView.showAnnotations([annotation], animated: true)
    }
    
    func configureUI() {
        reloadOrDeleteButton.backgroundColor = UIColor.blue
        if currentlySelected.count == 0 {
            reloadOrDeleteButton.setTitle("TAP FOR NEW COLLECTION", for: .normal)
        }
    }
    
    //Short-cut function when reloading table View
    
    func reloadCollectionView() {
        resetCollectionViewIndex()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.reloadOrDeleteButton.setTitle("TAP FOR NEW COLLECTION", for: .normal)
        }
    }
    
    //After deleting, reset the highlighted images
    
    func resetCollectionViewIndex() {
        
        for indexPath in collectionView.indexPathsForSelectedItems! {
            collectionView.deselectItem(at: indexPath, animated: false)
            collectionView.cellForItem(at: indexPath)?.contentView.alpha = 1.0
        }
    }
    
    //Delete images stored to photo Array in this View Controller (result of fr)
    
    func deletePhoto() {
        for image in coreDataPhotoArray {
            dataController.persistentContainer.viewContext.delete(image)
        }
    }
    
    // Search photos for a new location
    
    func freshSearch() {
        
        deletePhoto()
        coreDataPhotoArray.removeAll()
        collectionView.reloadData()
        resetCollectionViewIndex()
        reloadOrDeleteButton.isEnabled = false
        
        prepareFlickrImages { (images) in
            
            if images != nil {
                DispatchQueue.main.async {
                    self.savePhotosToCoreData(imagesToShow: images!, attachedPin: self.selectedPin)
                    self.reloadCollectionView()
                    self.reloadOrDeleteButton.isEnabled = true
                }
            }
        }
        
    }
    //Using Flickr API to search photos based on latitude and longitude (from injected DataController)
    
    func prepareFlickrImages(cvCompletion: @escaping (_ result: [FlickrImages]?) -> Void) {
        var filteredImages: [FlickrImages] = []
        FlickrNetwork.sharedInstance().getImages(lat: selectedPinCoords.latitude, long: selectedPinCoords.longitude) {success, images, error in
            if success {
                
                //Limit it to 21 random images initially (7 rows)
                
                if (images?.count)! > self.maxCellCount {
                    var randomIndexArray: [Int] = []
                    while randomIndexArray.count < self.maxCellCount {
                        let randomIndex = arc4random_uniform(UInt32((images?.count)!))
                        if !randomIndexArray.contains(Int(randomIndex)) { randomIndexArray.append(Int(randomIndex))}
                    }
                    for randomIndex in randomIndexArray {
                        filteredImages.append(images![randomIndex])
                    }
                    cvCompletion(filteredImages)
                } else {
                   cvCompletion(images)
                }
            } else {
                cvCompletion(nil)
            }
        }
    }
    
    // Save the images to coreData
    
    func savePhotosToCoreData(imagesToShow: [FlickrImages], attachedPin: Pin) {
        for image in imagesToShow {
            let photo = Photo(context: dataController.persistentContainer.viewContext)
            photo.imageData = nil
            photo.pin = selectedPin
            photo.imageURL = image.downloadImageData()
            coreDataPhotoArray.append(photo)
            do {
                try dataController.persistentContainer.viewContext.save()
            } catch {
                print("Error when saving core Data")
            }
        }
    }
    
    //Delete photos form core Data
    
    func deletePhotosFromCoreData() {
        
        for index in 0..<coreDataPhotoArray.count {
            if currentlySelected.contains(index) {
                dataController.persistentContainer.viewContext.delete(coreDataPhotoArray[index])
            }
        }
        do {
            try dataController.persistentContainer.viewContext.save()
        } catch {
            print("Error when deleting from Core Data")
        }
        currentlySelected.removeAll()
    }
    
    //2 different methods for one button based on the array of selected images
    
    @IBAction func buttonPressed(_ sender: Any) {
        
        if currentlySelected.count == 0 {
            freshSearch()
            }
        else {
            deletePhotosFromCoreData()
            resetCollectionViewIndex()
            coreDataPhotoArray = fetchedResultsControllerAndPhotoArray()!
            reloadCollectionView()
        }
    }
    
    //COLLECTION VIEW METHODS
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return coreDataPhotoArray.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CollectionViewCell
        cell.activityIndicator.startAnimating()
        cell.getImage(coreDataPhotoArray[indexPath.row])
        return cell
    }
    
    //Getting the collectionView to display 3x3 was figured out using StackOverflow - https://stackoverflow.com/questions/42698678/aligning-collection-view-cells-to-fit-exactly-3-per-row
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let yourWidth = collectionView.bounds.width/3.0
        let yourHeight = yourWidth
        
        return CGSize(width: yourWidth, height: yourHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func selectPhotos(_ indexPathArray: [IndexPath]) -> [Int] {
        var selected: [Int] = []
        
        for indexPath in indexPathArray {
            selected.append(indexPath.row)
            if selected.count != 0 {
                DispatchQueue.main.async {
                    self.reloadOrDeleteButton.setTitle("DELETE", for: .normal)
                }
            }
        }
        return selected
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        currentlySelected = selectPhotos(collectionView.indexPathsForSelectedItems!)
        let cell = collectionView.cellForItem(at: indexPath)
        DispatchQueue.main.async {
            cell?.contentView.alpha = 0.25
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        currentlySelected = selectPhotos(collectionView.indexPathsForSelectedItems!)
        let cell = collectionView.cellForItem(at: indexPath)
        DispatchQueue.main.async {
            cell?.contentView.alpha = 1.0
        }
    }
}
