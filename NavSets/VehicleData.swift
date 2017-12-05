//
//  VehicleData.swift
//  NavSets
//
//  Created by user133102 on 12/3/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import Foundation

class VehicleData{
    //MARK: Properties
    //Use this property to access data throughout application
    static var sharedInstance = VehicleData()
    
    //Table stores carbon emissions of different car make, models, and years in grams of CO2 per mile driven.
    //First field is make, second is model, third is year - all Strings
    //Derived from vehicle_data.csv asset
    var data: [String: [String: [String: Float]]] = [:]
    
    private init(){
        // read file
        guard let filepath = Bundle.main.path(forResource: "vehicle_data", ofType: "csv")
            else {
                fatalError("Missing vehicle_data.csv resource")
        }
        
        do {
            let contents = try String(contentsOfFile: filepath)
            let parsedCSV : [[String]] = contents.components(separatedBy: "\n").map{ $0.components(separatedBy: ",") }
            
            // find column indices of data of interest
            let headers = parsedCSV.first
            guard let makeIndex = headers!.index(of: "make"), let modelIndex = headers!.index(of: "model"), let yearIndex = headers!.index(of: "year"), let emissionsIndex = headers!.index(of: "co2TailpipeGpm") else {
                fatalError("Could not find columns needed in vehicle data")
            }
            
            for row in parsedCSV.dropFirst(){
                if row.indices.contains(makeIndex)  && row.indices.contains(modelIndex) && row.indices.contains(yearIndex) && row.indices.contains(emissionsIndex){
                    let make = row[makeIndex]
                    let model = row[modelIndex]
                    let year = row[yearIndex]
                    let emissions = Float(row[emissionsIndex])
                    
                    if data[make] == nil{
                        data[make] = [:]
                    }
                    if data[make]![model] == nil{
                        data[make]![model] = [:]
                    }
                    data[make]![model]![year] = emissions
                }
                
            }
        }
        catch {
            fatalError("Error parsing vehicle_data file")
        }
        
        
        
        

        
    }
}
