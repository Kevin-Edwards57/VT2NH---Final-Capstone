//
//  SavedEventsView.swift
//  VT2NH
//
//  Bookmarked events, newest save first, with past events separated out so the
//  upcoming list stays useful. Backed by SwiftData's @Query — no manual fetch,
//  and the list updates the instant a record changes anywhere in the app.
//

import SwiftUI
import SwiftData

struct SavedEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedEvent.start, order: .forward) private var savedEvents: [SavedEvent]

    private var upcoming: [SavedEvent] { savedEvents.filter { !$0.hasPassed } }
    private var past: [SavedEvent] { savedEvents.filter(\.hasPassed).reversed() }

    var body: some View {
        NavigationStack {
            Group {
                if savedEvents.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing saved yet", systemImage: "heart")
                    } description: {
                        Text("Tap the heart on any event and it will show up here.")
                    }
                } else {
                    List {
                        if !upcoming.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcoming) { row($0) }
                                    .onDelete { delete(upcoming, at: $0) }
                            }
                        }

                        if !past.isEmpty {
                            Section("Past") {
                                ForEach(past) { row($0).opacity(0.55) }
                                    .onDelete { delete(past, at: $0) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Saved")
            .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
            .toolbar {
                if !savedEvents.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) { EditButton() }
                }
            }
        }
    }

    private func row(_ saved: SavedEvent) -> some View {
        NavigationLink(value: saved.asEvent) {
            VStack(alignment: .leading, spacing: 4) {
                Text(saved.name)
                    .font(.headline)
                Label(saved.asEvent.fullDateLabel, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("\(saved.venueName) · \(saved.town), \(saved.state.abbreviation)",
                      systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
        }
    }

    private func delete(_ source: [SavedEvent], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(source[index])
        }
    }
}
