//
//  Route.swift
//  NavSets
//
//  Created by user133102 on 11/28/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import Mapbox

class RouteModel{
    //MARK: Properties
    var startLocation: CLLocationCoordinate2D
    var startName: String?
    var destinationLocation: CLLocationCoordinate2D
    var destinationName: String
    // var Route - the route object. Add in when mapbox navigation is all hooked up and ready to go
    
    //MARK: Initialization
    init?(startLocation: CLLocationCoordinate2D, startName: String?, destinationLocation: CLLocationCoordinate2D, destinationName: String){
        
        //Initialize stored properties
        self.startLocation = startLocation
        self.startName = startName
        self.destinationLocation = destinationLocation
        self.destinationName = destinationName
    }
}
