//
//  SettingsViewController.swift
//  NavSets
//
//  Created by user133102 on 11/30/17.
//  Copyright © 2017 Max Schuman. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    //MARK: Properties
    var userModel: UserModel?
    var data = VehicleData.sharedInstance.data
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    

    @IBOutlet weak var yearPicker: UIPickerView!
    @IBOutlet weak var modelPicker: UIPickerView!
    @IBOutlet weak var makePicker: UIPickerView!
    var makes: [String] = [""]
    var models: [String] = [""]
    var years: [String] = [""]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.makePicker.delegate = self
        self.makePicker.dataSource = self
        self.modelPicker.delegate = self
        self.modelPicker.dataSource = self
        self.yearPicker.delegate = self
        self.yearPicker.dataSource = self
        
        initializePickerData()
        setInitialPicks()
        setSaveEnabled()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UIPickerViewDelegate and UIPickerViewDataSource
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView{
        case self.makePicker:
            return self.makes.count
        case self.modelPicker:
            return self.models.count
        case self.yearPicker:
            return self.years.count
        default:
            return 0
        }
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView{
        case self.makePicker:
            return self.makes[row]
        case self.modelPicker:
            return self.models[row]
        case self.yearPicker:
            return self.years[row]
        default:
            return nil
        }
    }
    
    // Catpure the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        switch pickerView{
        case self.makePicker:
            let chosenMake = self.makes[row]
            if chosenMake != ""{
                self.models = data[chosenMake]!.keys.sorted()
                self.models.insert("", at: 0)
            }
            else {
                self.models = [""]
            }
            self.years = [""]
        case self.modelPicker:
            let make = self.makes[self.makePicker.selectedRow(inComponent: 0)]
            let chosenModel = self.models[row]
            if chosenModel != ""{
                self.years = data[make]![chosenModel]!.keys.sorted()
                self.years.insert("", at: 0)
            }
            else{
                self.years = [""]
            }
        default:
            var year = 0
        }
        
        // disable save button when the inputs are invalid
        
        self.makePicker.reloadAllComponents()
        self.modelPicker.reloadAllComponents()
        self.yearPicker.reloadAllComponents()
        setSaveEnabled()
        updateUserModel()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Private Methods
    func initializePickerData(){
        self.makes = data.keys.sorted()
        self.makes.insert("", at: 0)
        
        if let make = self.userModel?.carMake {
            self.models = data[make]!.keys.sorted()
            self.models.insert("", at: 0)
            if let model = self.userModel?.carModel {
                self.years = data[make]![model]!.keys.sorted()
                self.years.insert("", at: 0)
            }
            else{
                self.years = [""]
            }
            
        }
        else{
            self.models = [""]
            self.years = [""]
        }
    }
    
    func setInitialPicks(){
        if let make = self.userModel?.carMake{
            self.makePicker.selectRow(self.makes.index(of: make) ?? 0, inComponent: 0, animated: false)
        }
        else{
            self.makePicker.selectRow(0, inComponent: 0, animated: false)
        }
        
        if let model = self.userModel?.carModel{
            self.modelPicker.selectRow(self.models.index(of: model) ?? 0, inComponent: 0, animated: false)
        }
        else{
            self.modelPicker.selectRow(0, inComponent: 0, animated: false)
        }
        
        if let year = self.userModel?.carYear{
            self.yearPicker.selectRow(self.years.index(of: year) ?? 0, inComponent:0, animated: false)
        }
        else{
            self.yearPicker.selectRow(0, inComponent: 0, animated: false)
        }
    }
    
    func setSaveEnabled(){
        let make = self.makes[self.makePicker.selectedRow(inComponent: 0)]
        let model = self.models[self.modelPicker.selectedRow(inComponent: 0)]
        let year = self.years[self.yearPicker.selectedRow(inComponent: 0)]

        self.saveButton.isEnabled = make != "" && model != "" && year != ""

    }
    
    func updateUserModel(){
        if saveButton.isEnabled{
            self.userModel?.carMake = self.makes[self.makePicker.selectedRow(inComponent: 0)]
            self.userModel?.carModel = self.models[self.modelPicker.selectedRow(inComponent: 0)]
            self.userModel?.carYear = self.years[self.yearPicker.selectedRow(inComponent: 0)]
            self.userModel?.CO2GramsPerMile = self.data[(self.userModel?.carMake!)!]![(self.userModel?.carModel!)!]![(self.userModel?.carYear!)!]!
        }
        
    }
    
    
}
