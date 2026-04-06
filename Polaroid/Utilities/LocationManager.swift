import CoreLocation
import Observation

@MainActor
@Observable
final class LocationManager: NSObject {
    var cityName: String? = nil
    var isAuthorized = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            fetchLocation()
        default:
            break
        }
    }

    func fetchLocation() {
        guard isAuthorized else { return }
        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let city = placemarks?.first?.locality ?? placemarks?.first?.administrativeArea
            Task { @MainActor in
                self.cityName = city
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let captured = location
        Task { @MainActor in
            self.reverseGeocode(captured)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isAuthorized = true
                self.fetchLocation()
            default:
                self.isAuthorized = false
            }
        }
    }
}
