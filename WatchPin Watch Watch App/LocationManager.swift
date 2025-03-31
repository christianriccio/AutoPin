import Foundation
import CoreLocation
import WatchConnectivity
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, WCSessionDelegate {
    private let locationManager = CLLocationManager()
    private var session: WCSession?
    
    @Published var lastKnownLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var isUpdatingLocation: Bool = false
    @Published var lastMessageSent: Date?
    @Published var connectionState: WCSessionActivationState = .notActivated
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            self.session = session
            print("WCSession configurato e in attivazione")
        } else {
            print("WCSession non supportato su questo dispositivo")
        }
    }
    
    // MARK: - Gestione Posizione
    
    func requestLocation() {
        authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isUpdatingLocation = true
            locationManager.startUpdatingLocation()
        default:
            locationError = NSError(domain: "LocationManagerErrorDomain",
                                  code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Autorizzazione alla posizione negata"])
        }
    }
    
    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCSession attivazione fallita: \(error.localizedDescription)")
                self.locationError = error
                return
            }
            
            self.connectionState = activationState
            print("WCSession attivato con stato: \(activationState.rawValue)")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.lastKnownLocation = location
            self.stopUpdatingLocation()
            
            if let session = self.session, session.activationState == .activated && session.isReachable {
                let message = [
                    "watchLatitude": location.coordinate.latitude,
                    "watchLongitude": location.coordinate.longitude,
                    "timestamp": Date().timeIntervalSince1970
                ]
                
                session.sendMessage(message, replyHandler: { reply in
                    print("Messaggio inviato con successo: \(reply)")
                    DispatchQueue.main.async {
                        self.lastMessageSent = Date()
                    }
                }, errorHandler: { error in
                    print("Errore invio messaggio: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.locationError = error
                    }
                })
                
                print("Posizione inviata: Lat \(location.coordinate.latitude), Lon \(location.coordinate.longitude)")
            } else {
                print("WCSession non raggiungibile: \(String(describing: self.session?.activationState.rawValue))")
                self.locationError = NSError(domain: "WCSessionErrorDomain",
                                          code: 2,
                                          userInfo: [NSLocalizedDescriptionKey: "iPhone non raggiungibile"])
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
            self.isUpdatingLocation = false
            print("Errore posizione: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.requestLocation()
            }
        }
    }
}
