import Foundation
import MapKit

struct AppLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let wikiURL: URL?
    let town: String
    let state: String
}

struct LocationList {
    static let towns: [AppLocation] = [
        AppLocation(name: "Burlington, VT", coordinate: CLLocationCoordinate2D(latitude: 44.4759, longitude: -73.2121), wikiURL: URL(string: "https://en.m.wikipedia.org/wiki/Burlington,_Vermont"), town: "Burlington", state: "Vermont"),
        AppLocation(name: "Montpelier, VT", coordinate: CLLocationCoordinate2D(latitude: 44.2601, longitude: -72.5754), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Montpelier,_Vermont"), town: "Montpelier", state: "Vermont"),
        AppLocation(name: "Stowe, VT", coordinate: CLLocationCoordinate2D(latitude: 44.4654, longitude: -72.6874), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Stowe,_Vermont"), town: "Stowe", state: "Vermont"),
        AppLocation(name: "Lebanon, NH", coordinate: CLLocationCoordinate2D(latitude: 43.6423, longitude: -72.2524), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Lebanon,_New_Hampshire"), town: "Lebanon", state: "New Hampshire"),
        AppLocation(name: "Hanover, NH", coordinate: CLLocationCoordinate2D(latitude: 43.7022, longitude: -72.2896), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Hanover,_New_Hampshire"), town: "Hanover", state: "New Hampshire"),
        AppLocation(name: "Northfield, VT", coordinate: CLLocationCoordinate2D(latitude: 44.1534, longitude: -72.6584), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Northfield,_Vermont"), town: "Northfield", state: "Vermont"),
        AppLocation(name: "Barre, VT", coordinate: CLLocationCoordinate2D(latitude: 44.1970, longitude: -72.5020), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Barre,_Vermont"), town: "Barre", state: "Vermont"),
        AppLocation(name: "Rutland, VT", coordinate: CLLocationCoordinate2D(latitude: 43.6106, longitude: -72.9726), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Rutland,_Vermont"), town: "Rutland", state: "Vermont"),
        AppLocation(name: "White River Junction, VT", coordinate: CLLocationCoordinate2D(latitude: 43.6484, longitude: -72.3195), wikiURL: URL(string: "https://en.wikipedia.org/wiki/White_River_Junction,_Vermont"), town: "White River Junction", state: "Vermont"),
        AppLocation(name: "Middlebury, VT", coordinate: CLLocationCoordinate2D(latitude: 44.0153, longitude: -73.1673), wikiURL: URL(string: "https://en.wikipedia.org/wiki/Middlebury,_Vermont"), town: "Middlebury", state: "Vermont")
    ]
}
