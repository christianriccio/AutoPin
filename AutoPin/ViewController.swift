//
//  ViewController.swift
//  AutoPin
//
//  Created by Christian Riccio on 30/03/25.
//

import UIKit
import CoreLocation
import WatchConnectivity
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, WCSessionDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var saveLocationButton: UIButton!
    @IBOutlet weak var findCarButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var lastSavedTimeLabel: UILabel!
    @IBOutlet weak var carPositionView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Proprietà
    
    let locationManager = CLLocationManager()
    var carLocation: CLLocation?
    
    let carLatitudeKey = "CarLatitude"
    let carLongitudeKey = "CarLongitude"
    let carSavedTimeKey = "CarSavedTime"
    let carSavedByWatchKey = "CarSavedByWatch"
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureLocationManager()
        configureWatchConnectivity()
        
        loadSavedCarLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIWithSavedLocation()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        [saveLocationButton, findCarButton].forEach { button in
            button?.layer.cornerRadius = 12
            button?.clipsToBounds = true
            button?.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        }
        
        saveLocationButton.backgroundColor = UIColor.systemBlue
        saveLocationButton.setTitleColor(.white, for: .normal)
        
        findCarButton.backgroundColor = UIColor.systemGreen
        findCarButton.setTitleColor(.white, for: .normal)
        
        carPositionView.layer.cornerRadius = 16
        carPositionView.clipsToBounds = true
        carPositionView.backgroundColor = UIColor.secondarySystemBackground
        
        activityIndicator.hidesWhenStopped = true
        
        updateUIWithSavedLocation()
    }
    
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func configureWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            print("Watch Connectivity non è supportato su questo dispositivo.")
        }
    }
    
    // MARK: - Actions
    
    @IBAction func saveCarLocationTapped(_ sender: UIButton) {
        statusLabel.text = "Rilevamento posizione in corso..."
        activityIndicator.startAnimating()
        saveLocationButton.isEnabled = false
        
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func findCarLocationTapped(_ sender: UIButton) {
        guard let latitude = UserDefaults.standard.object(forKey: carLatitudeKey) as? Double,
              let longitude = UserDefaults.standard.object(forKey: carLongitudeKey) as? Double else {
            showAlert(title: "Nessuna Posizione Salvata", message: "Devi prima salvare la posizione della tua auto!")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mapVC = storyboard.instantiateViewController(withIdentifier: "MapViewControllerID") as? MapViewController {
            mapVC.carLatitude = latitude
            mapVC.carLongitude = longitude
            mapVC.modalPresentationStyle = .fullScreen
            present(mapVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadSavedCarLocation() {
        if let latitude = UserDefaults.standard.object(forKey: carLatitudeKey) as? Double,
           let longitude = UserDefaults.standard.object(forKey: carLongitudeKey) as? Double {
            carLocation = CLLocation(latitude: latitude, longitude: longitude)
        }
    }
    
    private func updateUIWithSavedLocation() {
        if let _ = carLocation,
           let timestamp = UserDefaults.standard.object(forKey: carSavedTimeKey) as? Date {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            lastSavedTimeLabel.text = "Salvata il: \(dateFormatter.string(from: timestamp))"
            
            let savedByWatch = UserDefaults.standard.bool(forKey: carSavedByWatchKey)
            statusLabel.text = savedByWatch ? "Posizione salvata da Apple Watch" : "Posizione salvata"
            
            carPositionView.isHidden = false
            findCarButton.isEnabled = true
        } else {
            carPositionView.isHidden = true
            statusLabel.text = "Nessuna posizione salvata"
            lastSavedTimeLabel.text = ""
            findCarButton.isEnabled = false
        }
    }
    
    private func saveCarPosition(latitude: Double, longitude: Double, fromWatch: Bool = false) {
        UserDefaults.standard.set(latitude, forKey: carLatitudeKey)
        UserDefaults.standard.set(longitude, forKey: carLongitudeKey)
        UserDefaults.standard.set(Date(), forKey: carSavedTimeKey)
        UserDefaults.standard.set(fromWatch, forKey: carSavedByWatchKey)
        UserDefaults.standard.synchronize()
        
        carLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        DispatchQueue.main.async {
            self.updateUIWithSavedLocation()
            self.activityIndicator.stopAnimating()
            self.saveLocationButton.isEnabled = true
            
            self.showLocationSavedAlert(fromWatch: fromWatch)
        }
    }
    
    private func showLocationSavedAlert(fromWatch: Bool = false) {
        let title = fromWatch ? "Posizione Salvata da Watch" : "Posizione Salvata"
        let message = fromWatch ?
            "La posizione della tua auto è stata salvata tramite il tuo Apple Watch!" :
            "La posizione della tua auto è stata salvata con successo!"
        
        showAlert(title: title, message: message)
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        print("Posizione rilevata: Lat \(latitude), Lon \(longitude)")
        
        locationManager.stopUpdatingLocation()
        saveCarPosition(latitude: latitude, longitude: longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errore durante l'ottenimento della posizione: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.statusLabel.text = "Errore: \(error.localizedDescription)"
            self.activityIndicator.stopAnimating()
            self.saveLocationButton.isEnabled = true
            
            self.showAlert(title: "Errore", message: "Impossibile ottenere la posizione: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Messaggio ricevuto dall'Apple Watch: \(message)")
        
        if let latitude = message["watchLatitude"] as? Double,
           let longitude = message["watchLongitude"] as? Double {
            
            saveCarPosition(latitude: latitude, longitude: longitude, fromWatch: true)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WC Session activated with state: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WC Session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
        print("WC Session did deactivate")
    }
}
