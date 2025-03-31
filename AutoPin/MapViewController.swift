import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Proprietà
    
    var carLatitude: Double?
    var carLongitude: Double?
    var carAnnotation: MKPointAnnotation?
    var routeOverlay: MKOverlay?
    
    let locationManager = CLLocationManager()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureLocationManager()
        configureMapView()
        showCarLocation()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        [navigateButton, backButton].forEach { button in
            button?.layer.cornerRadius = 12
            button?.clipsToBounds = true
        }
        
        infoView.layer.cornerRadius = 16
        infoView.clipsToBounds = true
        infoView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        
        activityIndicator.hidesWhenStopped = true
        
        navigateButton.isEnabled = false
    }
    
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func configureMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapGesture)
    }
    
    // MARK: - Actions
    
    @IBAction func dismissMapView(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func navigateToCarTapped(_ sender: UIButton) {
        calculateRoute()
    }
    
    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta / 2, longitudeDelta: mapView.region.span.longitudeDelta / 2)
        )
        
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func showCarLocation() {
        guard let latitude = carLatitude, let longitude = carLongitude else {
            showAlert(title: "Errore", message: "Coordinate dell'auto non disponibili")
            return
        }
        
        let carLocationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = carLocationCoordinate
        annotation.title = "La Tua Auto"
        mapView.addAnnotation(annotation)
        carAnnotation = annotation
        
        let region = MKCoordinateRegion(
            center: carLocationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        mapView.setRegion(region, animated: true)
    }
    
    private func calculateRoute() {
        guard let carLatitude = carLatitude,
              let carLongitude = carLongitude,
              let userLocation = locationManager.location else {
            showAlert(title: "Impossibile Calcolare il Percorso", message: "Posizione utente o auto non disponibile")
            return
        }
        
        activityIndicator.startAnimating()
        navigateButton.isEnabled = false
        
        let userCoordinate = userLocation.coordinate
        let carCoordinate = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
        
        if let routeOverlay = routeOverlay {
            mapView.removeOverlay(routeOverlay)
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: carCoordinate))
        request.transportType = .walking // Usa .walking per un percorso pedonale
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            self.navigateButton.isEnabled = true
            
            if let error = error {
                print("Errore nel calcolo delle indicazioni: \(error.localizedDescription)")
                self.showAlert(title: "Errore", message: "Impossibile calcolare il percorso: \(error.localizedDescription)")
                return
            }
            
            if let route = response?.routes.first {
                self.routeOverlay = route.polyline
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                
                let distanceInMeters = route.distance
                
                if distanceInMeters < 1000 {
                    self.distanceLabel.text = String(format: "Distanza: %.0f m", distanceInMeters)
                } else {
                    self.distanceLabel.text = String(format: "Distanza: %.2f km", distanceInMeters / 1000)
                }
                
                self.navigateButton.setTitle("Avvia Navigazione", for: .normal)
                
                self.showBothLocations(userLocation: userCoordinate, carLocation: carCoordinate)
            }
        }
    }
    
    private func showBothLocations(userLocation: CLLocationCoordinate2D, carLocation: CLLocationCoordinate2D) {
        let minLat = min(userLocation.latitude, carLocation.latitude)
        let maxLat = max(userLocation.latitude, carLocation.latitude)
        let minLon = min(userLocation.longitude, carLocation.longitude)
        let maxLon = max(userLocation.longitude, carLocation.longitude)
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let spanLat = (maxLat - minLat) * 1.5
        let spanLon = (maxLon - minLon) * 1.5
        
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        let span = MKCoordinateSpan(latitudeDelta: max(spanLat, 0.005), longitudeDelta: max(spanLon, 0.005))
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "CarAnnotation"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            let infoButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = infoButton
        } else {
            annotationView?.annotation = annotation
        }
        
        if let markerAnnotationView = annotationView as? MKMarkerAnnotationView {
            markerAnnotationView.markerTintColor = UIColor.red
            markerAnnotationView.glyphImage = UIImage(systemName: "car.fill")
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            showAlert(title: "Dettagli Posizione", message: "Questa è la posizione della tua auto salvata.")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, let carLatitude = carLatitude, let carLongitude = carLongitude {
            let carCoordinate = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)
            
            let carLocation = CLLocation(latitude: carLatitude, longitude: carLongitude)
            let distanceInMeters = location.distance(from: carLocation)
            
            DispatchQueue.main.async {
                if distanceInMeters < 1000 {
                    self.distanceLabel.text = String(format: "Distanza: %.0f m", distanceInMeters)
                } else {
                    self.distanceLabel.text = String(format: "Distanza: %.2f km", distanceInMeters / 1000)
                }
                
                self.navigateButton.isEnabled = true
            }
            
            if routeOverlay == nil {
                showBothLocations(userLocation: location.coordinate, carLocation: carCoordinate)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errore durante l'ottenimento della posizione dell'utente: \(error.localizedDescription)")
    }
}
