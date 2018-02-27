//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Yash Rao on 2/21/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var topNavBar: UINavigationBar!
    @IBOutlet weak var deleteButton: UIButton!
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataController: DataController!
    var pinArray: [Pin] = []
    var editMode: Bool = false
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    
    func fetchedResultsControllerAndPinArray() -> [Pin]? {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch cannot be completed: \(error.localizedDescription)")
        }
        
        do {
            let numberPins = try fetchedResultsController.managedObjectContext.count(for: fetchRequest)
            for index in 0..<numberPins {
                pinArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)))
            }
            return pinArray
        } catch {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        configureUI()
        makeGesture()
        fetchedResultsControllerAndPinArray()

        if pinArray != nil {
            for pin in pinArray {
                let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                addAnnotation(coordinates: coordinates)
            }
        }
    }
    
    func makeGesture() {
        var touchAndHoldGesture = UILongPressGestureRecognizer(target: self, action: #selector (touchAndHold))
        touchAndHoldGesture.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(touchAndHoldGesture)
    }
    
    func addAnnotation(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
    }
    
    @objc func touchAndHold(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addAnnotation(coordinates: coordinates)
            
            //Save to Persistent Store
            let pin = Pin(context: dataController.persistentContainer.viewContext)
            pin.latitude = coordinates.latitude
            pin.longitude = coordinates.longitude
            pinArray.append(pin)
            try? dataController.persistentContainer.viewContext.save()
        }
    }
    
    func deletepins(annotation: MKAnnotation) {
        
        let coord = annotation.coordinate
        for pin in pinArray {
            if pin.latitude == coord.latitude && pin.longitude == coord.longitude {
                do {
                    dataController.persistentContainer.viewContext.delete(pin)
                    try? dataController.persistentContainer.viewContext.save()
                } catch {
                    print("Error when removing pin from Core Data")
                }
                break
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if !editMode {
            performSegue(withIdentifier: "pinToPhotos", sender: view.annotation?.coordinate)
            mapView.deselectAnnotation(view.annotation, animated: false)
        } else {
            deletepins(annotation: view.annotation!)
            mapView.removeAnnotation(view.annotation!)
        }
    }
    
    func configureUI() {
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.title = "Virtual Tourist"
        self.deleteButton.backgroundColor = UIColor.red
        self.deleteButton.isHidden = true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deleteButton.isHidden = !editing
        editMode = editing
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinToPhotos" {
            if let vc = segue.destination as? CollectionViewAndMapViewController {
                let coord = sender as! CLLocationCoordinate2D
                vc.selectedPinCoords = coord
                
                for pin in pinArray {
                    if pin.longitude == coord.longitude && pin.latitude == coord.latitude {
                        vc.selectedPin = pin
                        vc.dataController = dataController
                    }
                }
            }
        }
    }
}

