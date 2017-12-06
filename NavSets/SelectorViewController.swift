//
//  SelectorViewController.swift
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
import UberRides
import Stripe

class SelectorViewController: UIViewController, UITextFieldDelegate, MGLMapViewDelegate, UITableViewDataSource, UITableViewDelegate, STPPaymentContextDelegate {
    //MARK: Properties
    @IBOutlet weak var destinationField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var originField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var routeDistanceAndTime: UILabel!
    @IBOutlet weak var carButton: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var walkButton: UIButton!
    @IBOutlet weak var bikeButton: UIButton!
    @IBOutlet weak var uberButton: UIButton!
    @IBOutlet weak var originGeocodeResultsTable: UITableView!
    @IBOutlet weak var destinationGeocodeResultsTable: UITableView!
    var mapView: MGLMapView!
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    var routeModel: RouteModel?
    var userModel: UserModel?
    var directionsRoute: Route?
    var originForwardGeocodeResults: Array<GeocodedPlacemark>?
    var destinationForwardGeocodeResults: Array<GeocodedPlacemark>?
    var launchUberButton = RideRequestButton()
    var selectedTransitButton: UIButton!
    let paymentContext: STPPaymentContext
    let customerContext: STPCustomerContext
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                if self.paymentInProgress {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.alpha = 1
                }
                else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.alpha = 0
                }
            }, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        customerContext = STPCustomerContext(keyProvider: MainAPIClient.sharedClient)
        paymentContext = STPPaymentContext(customerContext: customerContext)
        
        super.init(coder: aDecoder)
        paymentContext.delegate = self
        paymentContext.hostViewController = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add map view to base view
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        // top view comes down 150, bottom view goes up 125
        let mapFrame = CGRect(x: 0, y: 150, width: view.bounds.width, height: view.bounds.height - (150+125))
        mapView = MGLMapView(frame: mapFrame, styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter((routeModel?.startLocation)!, zoomLevel: 11, animated: false)
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView) // send the map view to the back, behind the other added UI elements
        
        // set self as delegate for text fields
        destinationField.delegate = self
        originField.delegate = self
        destinationField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        originField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        // set up the results tables
        destinationGeocodeResultsTable.delegate = self
        destinationGeocodeResultsTable.dataSource = self
        destinationGeocodeResultsTable.isHidden = true
        originGeocodeResultsTable.delegate = self
        originGeocodeResultsTable.dataSource = self
        originGeocodeResultsTable.isHidden = true
        
//        let destinationResultsTableFrame = CGRect(x: 20, y: destinationField.bounds.minY, width: 250, height: 230)
//        destinationGeocodeResultsTable.frame = destinationResultsTableFrame
//        destinationGeocodeResultsTable.frame.y = destinationField.bounds.minY
        // Add the geocoder
        geocoder = Geocoder.shared
        // Allow the map view to show the user's location
        mapView.showsUserLocation = true
        // Set the map view's delegate
        mapView.delegate = self
        
        // Make car the default mode of transit
        routeModel?.transitMode = .automobileAvoidingTraffic
        carButton?.isSelected = true
        selectedTransitButton = carButton
        
        // Set the origin field text to current location by default (and hide table because it shows on text update)
        originField.text = "Current Location"
        if let destinationName = routeModel?.destinationName {
             destinationField.text = destinationName
        }
        // add the destination point
        if let destinationLocation = routeModel?.destinationLocation {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = destinationLocation
            mapView.addAnnotation(annotation)
            // Calculate the route and put it on the map
            calculateRoute(from: (routeModel?.startLocation)!, to: (routeModel?.destinationLocation)!, transitMode: routeModel?.transitMode) { [unowned self] (route, error) in
                if error != nil {
                    // print an error message
                    print ("Error calculating route")
                }
                
            }
            
            
            
        }
        // add the launch uber button and make it hidden
        //TODO: fix the button's location
//        launchUberButton.center = startButton.center
        launchUberButton.frame = startButton.frame
        view.addSubview(launchUberButton)
        launchUberButton.isHidden = true
        
        // add rounding to corners of buttons
        self.startButton.layer.cornerRadius = 7
        self.backButton.layer.cornerRadius = 7
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Calculate route to use for navigation
    func calculateRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transitMode profileID: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic, completion: @escaping (Route?, Error?) -> ()) {

        let originWaypoint = Waypoint(coordinate: origin, name: "Start")
        let destinationWaypoint = Waypoint(coordinate: destination, name: "Finish")
        let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint], profileIdentifier: profileID)
        options.includesAlternativeRoutes = true
        
        // clear the previous annotations
        if (mapView.annotations != nil) {
            mapView.removeAnnotations(mapView.annotations!)
        }
        // If the destination point is different than the user's current location, add an annotation
        if ((destination.latitude != mapView.userLocation?.coordinate.latitude) || (destination.longitude != mapView.userLocation?.coordinate.longitude)) {
            let destinationAnnotation = MGLPointAnnotation()
            destinationAnnotation.coordinate = destination
            mapView.addAnnotation(destinationAnnotation)
        }

        // If the origin point is different than the user's current location and is not -180,-180 (which happens when the location hasn't been found yet), add an annotation
        let nullUserLocation = (mapView.userLocation?.coordinate.latitude == -180) && (mapView.userLocation?.coordinate.longitude == -180)
        if (!nullUserLocation && ((origin.latitude != mapView.userLocation?.coordinate.latitude) || (origin.longitude != mapView.userLocation?.coordinate.longitude)))  {
            let originAnnotation = MGLPointAnnotation()
            originAnnotation.coordinate = origin
            mapView.addAnnotation(originAnnotation)
        }

        _ = Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard error == nil else {
                print("Error calculating directions: \(error!)")
                return
            }

            // Reverse the list of routes so we can draw the main route last to make it the annotation on top
            let reversed = routes?.reversed()
            for route in reversed! {
                self.directionsRoute = route
                self.drawRoute(route: self.directionsRoute!, isMainRoute: route == routes?.first)
                let dist = (self.directionsRoute?.distance)! / 1609.34
                let time = Int((self.directionsRoute?.expectedTravelTime)! / 60)
                self.routeDistanceAndTime.text = ("\(String(time)) mins" + " (\(String(format: "%.1f", dist)) miles)")
            }
            var buttonString = "Start Directions"
            
            if let route = self.directionsRoute{
                var cost = 0.00
                if (profileID == .automobile) || (profileID == .automobileAvoidingTraffic){
                    cost = self.userModel!.offsetCost(route: route)
                    var payment = Int(cost * 100)
                    if (payment < 50 ){
                        payment += 50
                    }
                    self.paymentContext.paymentAmount = payment
                    buttonString = String(format: "Buy Route - $%.2f", cost)
                    
                }

                self.startButton.setTitle(buttonString, for: .normal)
                
            }
        }
        
        // Update the uber route parameters
        let dropoffLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let builder = RideParametersBuilder()
        builder.dropoffLocation = dropoffLocation
        builder.dropoffNickname = routeModel?.destinationName
        launchUberButton.rideParameters = builder.build()
    }
    
    func drawRoute(route: Route, isMainRoute: Bool) {
        guard route.coordinateCount > 0 else { return }
        // Convert the route's coordinates into a polyline
        var routeCoordinates = route.coordinates!
        let polyline = CustomPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
        polyline.color = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        if isMainRoute {
            polyline.color = #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1)
            polyline.width = 5.0
        }
        mapView.addAnnotation(polyline)
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        // Set the line color for polyline annotations
        if let annotation = annotation as? CustomPolyline {
            // Return dark gray if the polyline does not have a custom color.
            return annotation.color ?? .darkGray
        }
        // Fallback to the default tint color.
        return mapView.tintColor
    }
    
    // Present the navigation view controller
    func presentNavigation(along route: Route) {
        class CustomStyle: DayStyle {
            public required init() {
                super.init()
                mapStyleURL = URL(string: "mapbox://styles/mapbox/light-v9")!
            }
            
            override func apply() {
                super.apply()
                ManeuverView.appearance().backgroundColor = #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1)
                RouteTableViewHeaderView.appearance().backgroundColor = #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue:0.7994888425, alpha: 1)
                Button.appearance().textColor = .white
                DistanceLabel.appearance().textColor = .white
                DestinationLabel.appearance().textColor = .white
                ArrivalTimeLabel.appearance().textColor = .white
                TimeRemainingLabel.appearance().textColor = .white
                DistanceRemainingLabel.appearance().textColor = .white
                TurnArrowView.appearance().primaryColor = .white
                TurnArrowView.appearance().secondaryColor = .white
                LanesView.appearance().backgroundColor = .white
                LaneArrowView.appearance().primaryColor = .white
                CancelButton.appearance().tintColor = .white
            }
        }
        
        let viewController = NavigationViewController(for: route, locationManager: SimulatedLocationManager(route:route))
        self.present(viewController, animated: true, completion: nil)
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
        if (textField == destinationField) {
            destinationGeocodeResultsTable.isHidden = false
            view.bringSubview(toFront: destinationGeocodeResultsTable)
        }
        else if (textField == originField) {
            originGeocodeResultsTable.isHidden = false
            view.bringSubview(toFront: originGeocodeResultsTable)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        geocodingDataTask?.cancel()
        let options = ForwardGeocodeOptions(query: textField.text!)
        options.focalLocation = CLLocation(latitude: (mapView.userLocation?.coordinate.latitude)!, longitude: (mapView.userLocation?.coordinate.longitude)!)
        options.maximumResultCount = 10
        geocodingDataTask = geocoder.geocode(options) { [unowned self] (placemarks, attribution, error) in
            if let error = error {
                NSLog("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                if (textField == self.destinationField) {
                    self.destinationForwardGeocodeResults = placemarks
                    DispatchQueue.main.async{
                        self.destinationGeocodeResultsTable.reloadData()
                    }
                }
                else if (textField == self.originField) {
                    self.originForwardGeocodeResults = placemarks
                    DispatchQueue.main.async{
                        self.originGeocodeResultsTable.reloadData()
                    }
                }
            } else {
                print ("No results")
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //        routeModel!.destinationName = textField.text
        if (textField == destinationField) {
            destinationGeocodeResultsTable.isHidden = true
        }
        else if (textField == originField) {
            originGeocodeResultsTable.isHidden = true
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == originGeocodeResultsTable) {
            return originForwardGeocodeResults?.count ?? 10
        }
        else if (tableView == destinationGeocodeResultsTable) {
            return destinationForwardGeocodeResults?.count ?? 10
        }
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "forwardGeocodeResult", for: indexPath)
        if (tableView == originGeocodeResultsTable) {
            cell.textLabel?.text = originForwardGeocodeResults?[indexPath.item].qualifiedName
        }
        else if (tableView == destinationGeocodeResultsTable) {
            cell.textLabel?.text = destinationForwardGeocodeResults?[indexPath.item].qualifiedName
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var shouldCalculateRoute = true
        // we are updating the origin information
        if (tableView == originGeocodeResultsTable) {
            let placemark = originForwardGeocodeResults?[indexPath.item]
            // make sure an actual location cell was selected
            if (placemark != nil){
                // Update the route model and set the text in the search field
                self.routeModel!.startLocation = (placemark?.location.coordinate)!
                self.originField.text = placemark?.qualifiedName
                self.originField.endEditing(true)
            }
            else {
                shouldCalculateRoute = false
            }
        }
        // we are updating the destination information
        else if (tableView == destinationGeocodeResultsTable) {
            let placemark = destinationForwardGeocodeResults?[indexPath.item]
            // make sure an actual location cell was selected
            if (placemark != nil){
                // Update the route model and set the text in the search field
                self.routeModel!.destinationLocation = (placemark?.location.coordinate)!
                self.destinationField.text = placemark?.qualifiedName
                self.destinationField.endEditing(true)
            }
            else {
                shouldCalculateRoute = false
            }
        }
        if (shouldCalculateRoute) {
            // hide the table
            tableView.isHidden = true
            // recalculate and redraw the route
            calculateRoute(from: (routeModel?.startLocation)!, to: (routeModel?.destinationLocation)!, transitMode: routeModel?.transitMode) { [unowned self] (route, error) in
                if error != nil {
                    // print an error message
                    print ("Error calculating route")
                }
            }
        }
    }

    // MARK: Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? ""){
        case "Settings":
            guard let destination = segue.destination.childViewControllers.first as? SettingsViewController else {
                fatalError("Invalid destination controller: \(segue.destination)")
            }
            
            // update user model object for passing to settings view
            if let user = self.userModel{
                destination.userModel = user
            }
            else{
                self.userModel = UserModel()
                destination.userModel = self.userModel
            }
        default:
            var x = 0
        }
    }
    
    
    @IBAction func back(_ sender: UIButton) {
        if sender === backButton{
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func startNav(_ sender: UIButton) {
        if sender === startButton{
//            self.presentNavigation(along: directionsRoute!)
            self.paymentInProgress = true
            paymentContext.requestPayment()
        }
        
    }
    
    @IBAction func selectedTransit(_ sender:UIButton)
    {
        let transitButtons = [carButton, bikeButton, walkButton, uberButton, nil];
        for button in transitButtons {
            if (button == sender) {
                selectedTransitButton = button
                button?.isSelected = true
                routeModel?.transitMode = MBDirectionsProfileIdentifier.automobileAvoidingTraffic
                if (button == bikeButton) {
                    routeModel?.transitMode = MBDirectionsProfileIdentifier.cycling
                }
                else if (button == walkButton){
                    routeModel?.transitMode = MBDirectionsProfileIdentifier.walking
                }
                calculateRoute(from: (routeModel?.startLocation)!, to: (routeModel?.destinationLocation)!, transitMode: routeModel?.transitMode) { [unowned self] (route, error) in
                    if error != nil {
                        // print an error message
                        print ("Error calculating route")
                    }
                }
            }
            else {
                button?.isSelected = false
            }
        }
    }
    
    @IBAction func switchButton(_ sender: UIButton) {
        // Swap the start and destination locations and names
        let tempLocation = routeModel?.startLocation
        let tempName = routeModel?.startName
        routeModel?.startLocation = routeModel?.destinationLocation
        routeModel?.startName = routeModel?.destinationName
        routeModel?.destinationLocation = tempLocation
        routeModel?.destinationName = tempName
        // Swap the origin and destination field text entries
        let tempText = originField.text
        originField.text = destinationField.text
        destinationField.text = tempText
        calculateRoute(from: (routeModel?.startLocation)!, to: (routeModel?.destinationLocation)!, transitMode: routeModel?.transitMode) { [unowned self] (route, error) in
            if error != nil {
                // print an error message
                print ("Error calculating route")
            }
        }
    }
    //MARK: Actions
    @IBAction func unwindToSelector(sender: UIStoryboardSegue){
        if let sourceViewController = sender.source as? SettingsViewController, let user = sourceViewController.userModel {
            // set user model to be the model from the previous view
            self.userModel = user
            
            calculateRoute(from: (routeModel?.startLocation)!, to: (routeModel?.destinationLocation)!, transitMode: routeModel?.transitMode) { [unowned self] (route, error) in
                if error != nil {
                    // print an error message
                    print ("Error calculating route")
                }
            }
        }
    }
    
    // MARK: STPPaymentContextDelegate
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        print("[ERROR]: Unrecognized error while loading payment context: \(error)");
    }
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        print ("payment context changed")
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        // Create charge using payment result
        MainAPIClient.sharedClient.completeCharge(paymentResult,
                                                  amount: self.paymentContext.paymentAmount,
                                                  currency: "usd",
                                                  completion: completion)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        self.paymentInProgress = false
        let title: String
        let message: String
        switch status {
        case .error:
            title = "Error"
            message = error?.localizedDescription ?? ""
            print ("payment failure")
        case .success:
            title = "Success"
            message = "Route purchased"
            print ("payment success")
        case .userCancellation:
            return
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        var action = UIAlertAction(title: "OK", style: .default, handler: nil)
        if (selectedTransitButton == carButton && status == .success){
            action = UIAlertAction(title: "Start Navigation", style: .default, handler: {(action: UIAlertAction!) in self.presentNavigation(along: self.directionsRoute!)})
        }
        else if (selectedTransitButton == uberButton && status == .success){
            action = UIAlertAction(title: "Launch Uber", style: .default, handler: {(action: UIAlertAction!) in self.launchUberButton.requestBehavior.requestRide(parameters: self.launchUberButton.rideParameters)})
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }

}

// MGLPolyline subclass
class CustomPolyline: MGLPolylineFeature {
    var color: UIColor?
    var width: CGFloat?
}

