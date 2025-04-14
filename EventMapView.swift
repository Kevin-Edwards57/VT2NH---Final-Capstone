import SwiftUI
import MapKit

struct EventMapView: View {
    var events: [FBEvent]
    var location: AppLocation
    @Binding var position: MapCameraPosition

    var body: some View {
        VStack {
            Map(position: $position) {
                ForEach(events.compactMap { $0.coordinate != nil ? $0 : nil }, id: \.id) { event in
                    if let coord = event.coordinate {
                        Marker(event.name, coordinate: coord)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
    }
}

