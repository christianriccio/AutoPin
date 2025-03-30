//
//  LocationManager.swift
//  WatchPin Watch Watch App
//
//  Created by Christian Riccio on 30/03/25.
//

import Foundation
import CoreLocation
import WatchConnectivity

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, WCSessionDelegate {
    private let locationManager = CLLocationManager()
    private var session: WCSession! // Aggiungi questa proprietà

    @Published var lastKnownLocation: CLLocation?

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed on Watch with error: \(error.localizedDescription)")
            return
        }
        print("WC Session activated on Watch with state: \(activationState.rawValue)")
    }
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        if WCSession.isSupported() {
            session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            print("Watch Connectivity non è supportato su questo Apple Watch.")
        }
    }


    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
                self.lastKnownLocation = location
                self.stopUpdatingLocation()

                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                let message = ["watchLatitude": latitude, "watchLongitude": longitude]

                self.session.sendMessage(message, replyHandler: nil) { error in
                    print("Errore durante l'invio del messaggio all'iOS app: \(error.localizedDescription)")
                }
                print("Posizione inviata all'app iOS: Latitudine \(latitude), Longitudine \(longitude)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errore durante l'ottenimento della posizione sull'Apple Watch (SwiftUI): \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
    }
}
