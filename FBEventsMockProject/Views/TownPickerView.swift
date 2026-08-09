//
//  TownPickerView.swift
//  VT2NH
//
//  Sheet for choosing the town to browse. Offers the whole region, the town
//  nearest the user when location is available, and every covered town
//  grouped by state.
//

import SwiftUI

struct TownPickerView: View {
    @Bindable var store: EventStore
    var locationProvider: LocationProvider

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Derived, not hardcoded — adding a town to the catalog
                    // must not silently make this label a lie.
                    row(title: "Vermont & New Hampshire",
                        subtitle: "Everything, all \(LocationCatalog.towns.count) towns",
                        symbol: "map.fill",
                        tint: .accentColor,
                        isSelected: store.selectedTown == nil) {
                        store.selectedTown = nil
                        dismiss()
                    }
                }

                if locationProvider.isAuthorized {
                    if let nearest = locationProvider.nearestTown {
                        Section("Closest to you") {
                            townRow(nearest)
                        }
                    }
                } else {
                    Section {
                        Button {
                            locationProvider.requestLocation()
                        } label: {
                            Label("Find the town nearest me", systemImage: "location.fill")
                        }
                    } footer: {
                        Text("Used once to sort towns by distance. Nothing is stored or tracked.")
                    }
                }

                ForEach(USState.allCases) { state in
                    Section(state.rawValue) {
                        ForEach(LocationCatalog.towns.filter { $0.state == state }) { town in
                            townRow(town)
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func townRow(_ town: AppLocation) -> some View {
        row(title: town.name,
            subtitle: town.blurb,
            symbol: "building.2.fill",
            tint: Theme.tint(for: town.state),
            isSelected: store.selectedTown?.id == town.id) {
            store.selectedTown = town
            dismiss()
        }
    }

    private func row(title: String,
                     subtitle: String,
                     symbol: String,
                     tint: Color,
                     isSelected: Bool,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.callout)
                    .foregroundStyle(tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
