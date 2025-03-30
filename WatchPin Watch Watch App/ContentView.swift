import SwiftUI
import CoreLocationUI
import CoreLocation

struct ContentView: View {
    @StateObject var locationManager = LocationManager()

    var body: some View {
        VStack {
            Text("Posizione Auto")
                .font(.headline)
                .padding()

            if let location = locationManager.lastKnownLocation {
                Text("Latitudine: \(location.coordinate.latitude, specifier: "%.6f")")
                Text("Longitudine: \(location.coordinate.longitude, specifier: "%.6f")")
            } else {
                Text("Posizione non disponibile")
            }

            Button("Salva Posizione Auto") {
                locationManager.requestLocation()
            }
            .padding()
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }
}
