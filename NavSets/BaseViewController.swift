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


class BaseViewController: UIViewController, UITextFieldDelegate, MGLMapViewDelegate, GMSAutocompleteResultsViewControllerDelegate {
    //MARK: Properties
    @IBOutlet weak var locationSearchTextField: UITextField!
    
    
    var routeModel: RouteModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize route model with default arguments
        self.routeModel = RouteModel()
        
        // set self as delegate for text field
        locationSearchTextField.delegate = self
        
        // Add map view to base view
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 59.31, longitude: 18.06), zoomLevel: 9, animated: false)
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView) // send the map view to the back, behind the other added UI elements
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        navigationItem.titleView = searchController?.searchBar
//        let destSearch = UIView(frame: CGRect(x: 0, y: 20.0, width: 350.0, height: 45.0))
//        destSearch.addSubview((searchController?.searchBar)!)
//        view.addSubview(destSearch)
        searchController?.searchBar.sizeToFit()
        // when UISearchController presents the results view, present it in this view controller
        definesPresentationContext = true
        // prevent the nav bar from being hidden when searching
        searchController?.hidesNavigationBarDuringPresentation = false
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace) {
        if (mapView.annotations != nil) {
            mapView.removeAnnotations(mapView.annotations!)
        }
        searchController?.isActive = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        print("Place coordinate: \(String(describing: place.coordinate))")
        
        
        let annotation = MGLPointAnnotation()
        annotation.coordinate = place.coordinate
        annotation.title = "Start navigation"
        mapView.addAnnotation(annotation)
        
//        calculateRoute(from: (mapView.userLocation!.coordinate), to: annotation.coordinate) { [unowned self] (route, error) in
//            if error != nil {
//                // print an error message
//                print ("Error calculating route")
//            }
        }
        
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // handle the error
        print("Error: ", error.localizedDescription)
    }

    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide keyboard
        textField.resignFirstResponder()
        
        // Clear view
        clearRouteModel()
        
//        // Perform segue to selector view
//        performSegue(withIdentifier: "LocationSelected", sender: textField)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
//        routeModel!.destinationName = textField.text
        return
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
            
            // update route model object for passing to selector view
            if let destinationName = textField.text{
                self.routeModel!.destinationName = destinationName
                
                destination.routeModel = self.routeModel
            }
        default:
            fatalError("Did not recognize identifier: \(segue.identifier ?? "")")
            
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToBase(sender: UIStoryboardSegue){
        if let sourceViewController = sender.source as? SelectorViewController, let routeModel = sourceViewController.routeModel {
            // set route model to be the model from the previous view
            self.routeModel = routeModel
            updateRouteModel()
            


            
        }
    }
    
    //MARK: Private Methods
    private func updateRouteModel(){
        self.locationSearchTextField.text = routeModel?.destinationName
        // We can add code here that drops the pin on the map for the chosen location, sets the search bar to the location name, and centers the map on the chosen location
    }
    
    private func clearRouteModel(){
        self.routeModel = nil
        
        self.locationSearchTextField.text = nil
        
        // Add code here that clears out everything on view impacted by route model
    }

}

