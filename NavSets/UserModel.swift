//
//  UserModel.swift
//  NavSets
//
//  Created by user133102 on 11/30/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

class UserModel{
    // MARK: Properties
    // Can tack on additional properties as necessary
    var carMake: String?
    var carModel: String?
    var carYear: Int?
    
    var CO2GramsPerMile: Float?
    
    // MARK: Initialization
    init() {
        carMake = nil
        carModel = nil
        carYear = nil
        CO2GramsPerMile = nil
    }
    
    init?(carMake: String, carModel: String, carYear: Int){
        self.carMake = carMake
        self.carModel = carModel
        self.carYear = carYear
    }
    
    init?(carMake: String, carModel: String, carYear: Int, gramsPerMile: Float){
        self.carMake = carMake
        self.carModel = carModel
        self.carYear = carYear
        self.CO2GramsPerMile = gramsPerMile
    }
    
}
