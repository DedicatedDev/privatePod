//
//  LocationManager.swift
//  GravityXR
//
//  Created by Avinash Shetty on 5/13/20.
//  Copyright © 2020 GravityXR. All rights reserved.
//

import Foundation
import CoreLocation

public enum Proximity {
    case close
    case withinMile
    case withinCity
    case withinState
    case withinCountry
    case unknown
}

public class LocationManager: NSObject {
    
    static public let shared = LocationManager()

    // - Private
    private let locationManager = CLLocationManager()
    
    // - API
    public var exposedLocation: CLLocation? {
        return self.locationManager.location
    }

    private override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
    }

}


// MARK: - Core Location Delegate
extension LocationManager: CLLocationManagerDelegate {
    
    
    public func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {

        switch status {
    
        case .notDetermined         : print("notDetermined")        // location permission not asked for yet
        case .authorizedWhenInUse   : print("authorizedWhenInUse")  // location authorized
        case .authorizedAlways      : print("authorizedAlways")     // location authorized
        case .restricted            : print("restricted")           // TODO: handle
        case .denied                : print("denied")               // TODO: handle
        }
    }
}




// MARK: - Get Placemark
extension LocationManager {
    
    
    public func getPlace(for location: CLLocation,
                  completion: @escaping (CLPlacemark?) -> Void) {
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            
            guard error == nil else {
                print("*** Error in \(#function): \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?[0] else {
                print("*** Error in \(#function): placemark is nil")
                completion(nil)
                return
            }
            
            completion(placemark)
        }
    }
}



// MARK: - Get Location
extension LocationManager {
    
    
    public func getLocation(forPlaceCalled name: String,
                            completion: @escaping(CLLocation?) -> Void) {
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(name) { placemarks, error in
            
            guard error == nil else {
                print("*** Error in \(#function): \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?[0] else {
                print("*** Error in \(#function): placemark is nil")
                completion(nil)
                return
            }
            
            guard let location = placemark.location else {
                print("*** Error in \(#function): placemark is nil")
                completion(nil)
                return
            }

            completion(location)
        }
    }
    
    public func distanceFromLocation(with coordinate: CLLocation) -> Proximity {
        
        guard let coordinate₀ = self.exposedLocation else {return Proximity.unknown}
        
        let distanceInMeters = coordinate₀.distance(from: coordinate) // result is in meters

        if(distanceInMeters <= 50){
            return Proximity.close
        }else if(distanceInMeters <= 1609){
            return Proximity.withinMile
        }else if(distanceInMeters <= 11609){
            return Proximity.withinCity
        }else if(distanceInMeters <= 111609){
            return Proximity.withinState
        }else if(distanceInMeters <= 1111111){
            return Proximity.withinCountry
        }else {
            return Proximity.unknown
        }
    }
    
}
