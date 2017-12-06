//
//  OffsetCalculations.swift
//  NavSets
//
//  Created by Adam Greenstein on 11/29/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

struct carMakeAndModel {
    static let carMake = "firstStringKey"
    static let carModel = "secondStringKey"
}


// Here is where we do the carbon emission calculations

class carbonCost{
    //MARK: Properties
    var distance: Float? //distance is in meters
    var mpg: Float?
    // var Route - the route object. Add in when mapbox navigation is all hooked up and ready to go
    
    //MARK: Initialization
    init() {
        //Initialize stored properties
        self.distance = nil
        self.mpg = 25.0 // idk just set it to 25 mpg to start
    }
    init?(distance: Float, mpg: Float) {
        //Initialize stored properties
        self.distance = distance
        self.mpg = mpg
    }
}
