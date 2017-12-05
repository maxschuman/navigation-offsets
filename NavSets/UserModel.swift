//
//  UserModel.swift
//  NavSets
//
//  Created by user133102 on 11/30/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import Mapbox
import MapboxDirections

class UserModel{
    // MARK: Properties
    // Can tack on additional properties as necessary
    var carMake: String?
    var carModel: String?
    var carYear: String?
    
    var CO2GramsPerMile: Float?
    let EMISSIONSCONSTANT: Float = 500.0
    
    // MARK: Initialization
    init() {
        carMake = nil
        carModel = nil
        carYear = nil
        CO2GramsPerMile = nil
    }
    
    init?(carMake: String, carModel: String, carYear: String){
        self.carMake = carMake
        self.carModel = carModel
        self.carYear = carYear
    }
    
    init?(carMake: String, carModel: String, carYear: String, gramsPerMile: Float){
        self.carMake = carMake
        self.carModel = carModel
        self.carYear = carYear
        self.CO2GramsPerMile = gramsPerMile
    }
    
    //MARK: Methods
    func offsetCost(route: Route) -> Double{
        let emissions = self.CO2GramsPerMile ?? EMISSIONSCONSTANT
        
        let distanceMeters = Float(route.distance)
        let metersToMiles = Float(0.000621371)
        let gramsToPounds = Float(0.00220462)
        let poundsToCents = Float(0.00499)
        
        let cost = distanceMeters * metersToMiles * emissions * gramsToPounds * poundsToCents
        //return greater of cost or one cent
        return max(Double(round(100 * Double(cost))/100), 0.01)
        
        
    }
    
}
