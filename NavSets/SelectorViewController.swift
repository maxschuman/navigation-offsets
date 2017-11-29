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

class SelectorViewController: UIViewController, MGLMapViewDelegate {
    //MARK: Properties
    @IBOutlet weak var destinationField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var originField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    var mapView: MGLMapView!
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    var routeModel: RouteModel?
    var directionsRoute: Route?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add map view to base view
        let url = URL(string: "mapbox://styles/mapbox/streets-v10")
        mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 42.0493, longitude:-87.6819), zoomLevel: 11, animated: false)
        view.addSubview(mapView)
        view.sendSubview(toBack: mapView) // send the map view to the back, behind the other added UI elements
        
        // Add the geocoder
        geocoder = Geocoder.shared
        // Allow the map view to show the user's location
        mapView.showsUserLocation = true
        // Set the map view's delegate
        mapView.delegate = self
        
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
            calculateRoute(from: (routeModel?.startLocation)!, to: (routeModel?.destinationLocation)!) { [unowned self] (route, error) in
                if error != nil {
                    // print an error message
                    print ("Error calculating route")
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Calculate route to use for navigation
    func calculateRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (Route?, Error?) -> ()) {

        let originWaypoint = Waypoint(coordinate: origin, name: "Start")
        let destinationWaypoint = Waypoint(coordinate: destination, name: "Finish")
        let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint], profileIdentifier: .automobileAvoidingTraffic)
        options.includesAlternativeRoutes = true

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
            }
        }
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
        self.mapView.addAnnotation(polyline)
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

    // MARK: Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    }
    
    
    @IBAction func back(_ sender: UIButton) {
        if sender === backButton{
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func startNav(_ sender: UIButton) {
        if sender === startButton{
            self.presentNavigation(along: directionsRoute!)
        }
        
    }
    
    //MARK: Actions
    
}

// MGLPolyline subclass
class CustomPolyline: MGLPolylineFeature {
    var color: UIColor?
    var width: CGFloat?
}

