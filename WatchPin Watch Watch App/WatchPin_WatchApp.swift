//
//  WatchPin_WatchApp.swift
//  WatchPin Watch Watch App
//
//  Created by Christian Riccio on 30/03/25.
//
import SwiftUI

@main
struct WatchPin_WatchApp: App {
    @StateObject var locationManager = LocationManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
        }
    }
}
