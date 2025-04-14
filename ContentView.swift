import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Browse Locations")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Image("DiscoverIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)

                Text("VT2NH")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Find events by town across Vermont and New Hampshire")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                //  View Saved Events Button
                NavigationLink(destination: SavedEventsView()) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("View Saved Events")
                            .font(.subheadline)
                    }
                    .foregroundColor(.red)
                    .padding(.vertical, 6)
                }

                //  Town List
                List(LocationList.towns) { location in
                    NavigationLink(destination: LocationDetailView(location: location)) {
                        VStack(alignment: .leading) {
                            Text(location.name)
                                .font(.headline)
                            Text("Tap to view more")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding(.top)
        }
    }
}

