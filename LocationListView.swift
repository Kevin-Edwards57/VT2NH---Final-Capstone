import SwiftUI

struct LocationListView: View {
    var onLocationSelect: ((AppLocation) -> Void)? = nil

    var body: some View {
        List(LocationList.towns) { location in
            Button {
                onLocationSelect?(location)
            } label: {
                VStack(alignment: .leading) {
                    Text(location.name)
                        .font(.headline)
                    Text("Tap to view events")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Browse Locations")
    }
}

