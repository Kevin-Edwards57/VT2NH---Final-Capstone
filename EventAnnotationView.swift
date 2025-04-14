import SwiftUI
import MapKit

struct EventAnnotationView: View {
    let eventName: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
                .font(.title)
                .foregroundColor(.red)
            Text(eventName)
                .font(.caption)
                .fixedSize()
        }
    }
}
