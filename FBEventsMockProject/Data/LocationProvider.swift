//
//  LocationProvider.swift
//  VT2NH
//
//  Wraps CLLocationManager for the "Near me" sort. Deliberately minimal:
//  the app asks for a location once, uses it to order a list, and stops.
//  Nothing here runs in the background or tracks the user over time.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {

    private(set) var currentLocation: CLLocation?
    private(set) var authorization: CLAuthorizationStatus = .notDetermined

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorization = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    /// Asks for permission if needed, then takes a single fix.
    func requestLocation() {
        switch authorization {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    /// The town closest to the user, or nil when there is no fix yet.
    var nearestTown: AppLocation? {
        guard let currentLocation else { return nil }
        return LocationCatalog.towns.min {
            $0.location.distance(from: currentLocation) < $1.location.distance(from: currentLocation)
        }
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if self.isAuthorized { manager.requestLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in self.currentLocation = location }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        // A missed fix just means "Near me" stays unavailable; nothing to show.
    }
}
