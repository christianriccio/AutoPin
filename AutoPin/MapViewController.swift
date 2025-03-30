import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    
    @IBAction func dismissMapView(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var mapView: MKMapView!

    var carLatitude: Double?
    var carLongitude: Double?

    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    
    override func viewDidLoad() {
            super.viewDidLoad()

            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()

            mapView.showsUserLocation = true
            mapView.delegate = self

            if let latitude = carLatitude, let longitude = carLongitude {
                let carLocationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                if let userCoordinate = locationManager.location?.coordinate {
                    showBothLocations(userLocation: userCoordinate, carLocation: carLocationCoordinate)
                } else {
                    let region = MKCoordinateRegion(center: carLocationCoordinate, latitudinalMeters: 500, longitudinalMeters: 500)
                    mapView.setRegion(region, animated: true)
                }

                let annotation = MKPointAnnotation()
                annotation.coordinate = carLocationCoordinate
                annotation.title = "La Tua Auto"
                mapView.addAnnotation(annotation)
            }
        }

    func showBothLocations(userLocation: CLLocationCoordinate2D, carLocation: CLLocationCoordinate2D) {
        // Calcola i limiti per contenere entrambi i punti
        let minLat = min(userLocation.latitude, carLocation.latitude)
        let maxLat = max(userLocation.latitude, carLocation.latitude)
        let minLon = min(userLocation.longitude, carLocation.longitude)
        let maxLon = max(userLocation.longitude, carLocation.longitude)

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.5
        let spanLon = (maxLon - minLon) * 1.5

        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        let span = MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        let region = MKCoordinateRegion(center: center, span: span)

        mapView.setRegion(region, animated: true)
    }

    @IBAction func navigateToCarTapped(_ sender: UIButton) {
        if let carLatitude = carLatitude, let carLongitude = carLongitude, let userCoordinate = locationManager.location?.coordinate {
            let destinationCoordinate = CLLocationCoordinate2D(latitude: carLatitude, longitude: carLongitude)

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self else { return }
                if let error = error {
                    print("Errore nel calcolo delle indicazioni: \(error.localizedDescription)")
                    
                    return
                }

                if let route = response?.routes.first {
                    print("Percorso trovato!")
                    self.mapView.removeOverlays(self.mapView.overlays)
                    self.mapView.addOverlay(route.polyline, level: .aboveRoads)

                    
                    let rect = route.polyline.boundingMapRect
                    self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
                }
            }
        } else {
            print("Posizione dell'auto o dell'utente non disponibile per la navigazione.")
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
            if let latitude = carLatitude, let longitude = carLongitude {
                let carLocationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                showBothLocations(userLocation: location.coordinate, carLocation: carLocationCoordinate)
            }
           // locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errore durante l'ottenimento della posizione dell'utente in MapViewController: \(error.localizedDescription)")
    }
}
