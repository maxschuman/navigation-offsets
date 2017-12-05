//
//  Route.swift
//  NavSets
//
//  Created by user133102 on 11/28/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import Mapbox
import MapboxDirections

class RouteModel{
    //MARK: Properties
    var startLocation: CLLocationCoordinate2D?
    var startName: String?
    var destinationLocation: CLLocationCoordinate2D?
    var destinationName: String?
    var transitMode: MBDirectionsProfileIdentifier?
    
    //MARK: Initialization
    init() {
        //Initialize stored properties
        self.startLocation = nil
        self.startName = nil
        self.destinationLocation = nil
        self.destinationName = nil
        self.transitMode = nil
    }
    init?(startLocation: CLLocationCoordinate2D, startName: String?, destinationLocation: CLLocationCoordinate2D, destinationName: String, transitMode: MBDirectionsProfileIdentifier?, userLocation: CLLocationCoordinate2D){
        
        //Initialize stored properties
        self.startLocation = startLocation
        self.startName = startName
        self.destinationLocation = destinationLocation
        self.destinationName = destinationName
        self.transitMode = transitMode
    }
}
