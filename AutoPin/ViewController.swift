//
//  ViewController.swift
//  AutoPin
//
//  Created by Christian Riccio on 30/03/25.
//

import UIKit
import CoreLocation
import WatchConnectivity

class ViewController: UIViewController, CLLocationManagerDelegate, WCSessionDelegate {
    
    
    // MARK: - WCSessionDelegate (Ricezione Messaggi dall'Apple Watch)
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: (([String : Any]) -> Void)? = nil) {
        print("Messaggio ricevuto dall'Apple Watch: \(message)")
        
        if let latitude = message["watchLatitude"] as? Double,
           let longitude = message["watchLongitude"] as? Double {
            
            // Salva la posizione ricevuta da Watch nell'UserDefaults
            UserDefaults.standard.set(latitude, forKey: carLatitudeKey)
            UserDefaults.standard.set(longitude, forKey: carLongitudeKey)
            UserDefaults.standard.synchronize()
            
            print("Posizione dell'auto salvata tramite Apple Watch: Latitudine \(latitude), Longitudine \(longitude)")
            
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Posizione Salvata da Watch", message: "La posizione della tua auto è stata salvata tramite il tuo Apple Watch!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error as NSError? {
            print("WC Session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WC Session activated with state: \(activationState.rawValue)")
    }
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WC Session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
        print("WC Session did deactivate")
    }
#endif
    
    
    let locationManager = CLLocationManager()
    
    var carLocation : CLLocation?
    
    let carLatitudeKey = "CarLatitude"
    let carLongitudeKey = "CarLongitude"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //        if WCSession.isSupported() {
        let session = WCSession.default
        session.delegate = self
        session.activate()
        //        } else {
        //            print("Watch Connectivity non è supportato su questo dispositivo.")
        //        }
        
    }
    
    @IBAction func findCarLocationTapped(_ sender: UIButton) {
        if let savedLatitude = UserDefaults.standard.double(forKey: carLatitudeKey) as? Double,
           let savedLongitude = UserDefaults.standard.double(forKey: carLongitudeKey) as? Double {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let mapVC = storyboard.instantiateViewController(withIdentifier: "MapViewControllerID") as? MapViewController {
                mapVC.carLatitude = savedLatitude
                mapVC.carLongitude = savedLongitude
                present(mapVC, animated: true, completion: nil)
            }
            
        } else {
            print("Nessuna posizione dell'auto salvata.")
            let alertController = UIAlertController(title: "Nessuna Posizione Salvata", message: "Devi prima salvare la posizione della tua auto!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func saveCarLocationTapped(_ sender: UIButton) {
        locationManager.startUpdatingLocation()
        print("Richiesta la posizione...")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            carLocation = location
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            print("Latitudine: \(latitude), Longitudine: \(longitude)")
            
            UserDefaults.standard.set(latitude, forKey: carLatitudeKey)
            UserDefaults.standard.set(longitude, forKey: carLongitudeKey)
            UserDefaults.standard.synchronize()
            
            locationManager.stopUpdatingLocation()
            print("Posizione dell'auto salvata!")
            
            showLocationSavedAlert()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errore durante l'ottenimento della posizione: \(error.localizedDescription)")
    }
    
    func showLocationSavedAlert() {
        let alertController = UIAlertController(title: "Posizione Salvata", message: "La posizione della tua auto è stata salvata con successo!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
