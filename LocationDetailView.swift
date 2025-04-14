import SwiftUI

struct LocationDetailView: View {
    let location: AppLocation
    @Environment(\.openURL) var openURL
    @State private var showEvents = false
    @State private var startInMapMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(location.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("State: \(location.state)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Divider().padding(.vertical, 10)

                // 📚 Wikipedia Button
                Button {
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

                // 🎯 Center Map Button
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

                // 📅 View Events Button
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
            .navigationDestination(isPresented: $showEvents) {
                LocationExplorerView(location: location, startInMapMode: startInMapMode)
            }
        }
    }
}

