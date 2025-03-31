import SwiftUI
import CoreLocationUI
import CoreLocation

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("CaPin")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                locationStatusView
                
                Spacer()
                
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Label {
                        Text("Salva Posizione")
                            .font(.system(size: 16, weight: .medium))
                    } icon: {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(locationManager.isUpdatingLocation)
                
                if locationManager.isUpdatingLocation {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 5)
                }
                
                Spacer()
            }
            .padding()
            .alert("Posizione Salvata!", isPresented: $showingSuccess) {
                Button("OK") {}
            }
            .alert("Errore", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onReceive(locationManager.$lastMessageSent) { newValue in
                if newValue != nil {
                    showingSuccess = true
                }
            }
            .onReceive(locationManager.$locationError) { newError in
                if let error = newError {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private var locationStatusView: some View {
        Group {
            if let location = locationManager.lastKnownLocation {
                VStack(spacing: 8) {
                    Text("Ultima posizione:")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(String(format: "%.6f", location.coordinate.latitude))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.6f", location.coordinate.longitude))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let timestamp = locationManager.lastMessageSent {
                        Text("Inviato " + timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                            .padding(.top, 2)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                )
            } else {
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    Text("In attesa di autorizzazione...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                case .denied, .restricted:
                    Text("Accesso alla posizione negato")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                default:
                    Text("Posizione non ancora rilevata")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
