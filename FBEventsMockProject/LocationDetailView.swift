// Kevin Edwards
// Capstone Project
// VT2MH



import SwiftUI
/// Displays detailed information for a selected location (town).
/// Includes buttons to view town info via Wikipedia, center the event map,
/// and view upcoming Facebook events in either list or map mode.

struct LocationDetailView: View {
   
/// The selected AppLocation to show details for
    let location: AppLocation

    /// Used to open external links (e.g. Wikipedia)
    @Environment(\.openURL) var openURL
    /// Triggers navigation to LocationExplorerView
    /// Determines if the event view should launch in map mode

    @State private var showEvents = false
    
    /// Determines if the event view should launch in map mode
    @State private var startInMapMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Location Name
                Text(location.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                //  State Label
                Text("State: \(location.state)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider().padding(.vertical, 10)

                // 📚 Wikipedia Button
                Button {
                    // Build a Wikipedia URL using the town + state

                    let wikiSearch = "\(location.town),_\(location.state)"
                        .replacingOccurrences(of: " ", with: "_")
                    if let url = URL(string: "https://en.wikipedia.org/wiki/\(wikiSearch)") {
                        openURL(url)
                    }
                } label: {
                    Label("Information", systemImage: "book.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                // 🎯 Center Map Button ( launches event map focused on location)
                Button {
                    startInMapMode = true
                    showEvents = true
                } label: {
                    Label("Center Map", systemImage: "viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                // 📅 View Events Button (launches event list view)
                Button {
                    startInMapMode = false
                    showEvents = true
                } label: {
                    Label("View Events", systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(location.town)
            .navigationBarTitleDisplayMode(.inline)
            //Navigation to the event browser (map or list based on toggle)
            .navigationDestination(isPresented: $showEvents) {
                LocationExplorerView(location: location, startInMapMode: startInMapMode)
            }
        }
    }
}

