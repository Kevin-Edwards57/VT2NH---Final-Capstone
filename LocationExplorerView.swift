import SwiftUI
import MapKit

enum ViewType: String, CaseIterable {
    case list = "List"
    case map = "Map"
}

struct LocationExplorerView: View {
    let location: AppLocation
    let startInMapMode: Bool

    @StateObject private var viewModel = EventViewModel()
    @State private var selectedView: ViewType
    @State private var selectedEvent: FBEvent? = nil
    @State private var cameraPosition: MapCameraPosition

    init(location: AppLocation, startInMapMode: Bool = false) {
        self.location = location
        self.startInMapMode = startInMapMode
        _selectedView = State(initialValue: startInMapMode ? .map : .list)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        ))
    }

    var body: some View {
        VStack {
            Text("FB Events")
                .font(.title)
                .bold()
                .padding(.top, 4)

            NavigationLink("Browse All Locations") {
                ContentView()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.top, 4)

            Text("\(location.town), \(location.state)")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Events near \(location.town): \(viewModel.filteredEvents(for: location).count)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Picker("View", selection: $selectedView) {
                ForEach(ViewType.allCases, id: \.self) { view in
                    Text(view.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if selectedView == .list {
                List(viewModel.filteredEvents(for: location)) { event in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.name)
                            .font(.headline)
                        Text(event.formattedDate)
                            .font(.subheadline)
                        if let venue = event.place?.name {
                            Text(venue)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let desc = event.description {
                            Text(desc)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        selectedEvent = event
                    }
                }
                .listStyle(.inset)
                .sheet(item: $selectedEvent) { event in
                    EventDetailSheet(event: event)
                }
            } else {
                EventMapView(
                    events: viewModel.filteredEvents(for: location),
                    location: location,
                    position: $cameraPosition
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            viewModel.fetchEvents()
        }
        .navigationTitle(location.town)
        .navigationBarTitleDisplayMode(.inline)
    }
}

