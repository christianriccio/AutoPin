//
//  ViewController.swift
//  AutoPin
//
//  Created by Christian Riccio on 30/03/25.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()

    var carLocation : CLLocation?

    let carLatitudeKey = "CarLatitude"
    let carLongitudeKey = "CarLongitude"

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
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
            // Potremmo mostrare un messaggio se non ci sono coordinate salvate
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
        // Qui potremmo mostrare un messaggio di errore all'utente
    }

    func showLocationSavedAlert() {
        let alertController = UIAlertController(title: "Posizione Salvata", message: "La posizione della tua auto è stata salvata con successo!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
