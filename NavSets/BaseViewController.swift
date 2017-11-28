//
//  ViewController.swift
//  NavSets
//
//  Created by user133102 on 11/27/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import UIKit
import Mapbox

class BaseViewController: UIViewController, UITextFieldDelegate {
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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

