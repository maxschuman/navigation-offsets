//
//  ViewController.swift
//  NavSets
//
//  Created by user133102 on 11/27/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxGeocoder
import GooglePlaces


class BaseViewController: UIViewController, UITextFieldDelegate, MGLMapViewDelegate {
    //MARK: Properties
    @IBOutlet weak var locationSearchTextField: UITextField!
    var mapView: MGLMapView!
    var destinationName: String?
    var route: Route?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set self as delegate for text field
        locationSearchTextField.delegate = self
        
        // Add map view to base view
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 59.31, longitude: 18.06), zoomLevel: 9, animated: false)
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView) // send the map view to the back, behind the other added UI elements
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // handle the error
        print("Error: ", error.localizedDescription)
    }
    
    // Calculate route to use for navigation
    func calculateRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (Route?, Error?) -> ()) {
        
        let originWaypoint = Waypoint(coordinate: origin, name: "Start")
        
        let destinationWaypoint = Waypoint(coordinate: destination, name: "Finish")
        
        let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint], profileIdentifier: .automobileAvoidingTraffic)
        options.includesAlternativeRoutes = true
        
        _ = Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard error == nil else {
                print("Error calculating directions: \(error!)")
                return
            }
            
            // Reverse the list of routes so we can draw the main route last to make it the annotation on top
            let reversed = routes?.reversed()
            for route in reversed! {
                self.route = route
//                self.drawRoute(route: self.directionsRoute!, isMainRoute: route == routes?.first)
//                //                self.bv?.time = Float(route.expectedTravelTime.truncatingRemainder(dividingBy: 60))
//                // This isn't working
//                self.bv?.time = Float(route.expectedTravelTime)
//                print (self.bv?.time)
            }
        }
    }

    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide keyboard
        textField.resignFirstResponder()
        
//        // Perform segue to selector view
//        performSegue(withIdentifier: "LocationSelected", sender: textField)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        destinationName = textField.text
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // perform appropriate setup for destination controller
        let id = segue.identifier
        let destinationController = segue.destination
        switch(id ?? ""){
        case "LocationSelected":
            guard let destination = destinationController as? SelectorViewController else {
                fatalError("Invalid destination controller: \(segue.destination)")
            }
            
            guard let textField = sender as? UITextField else {
                fatalError("Invalid sender: \(sender)")
            }
            
            if let destinationName = textField.text {
                destination.destinationName = destinationName
            }
        default:
            fatalError("Did not recognize identifier: \(segue.identifier ?? "")")
            
        }
    }


}

