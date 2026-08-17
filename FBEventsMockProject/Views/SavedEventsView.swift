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
                            Section {
                                ForEach(upcoming) { row($0) }
                                    .onDelete { delete(upcoming, at: $0) }
                            } header: {
                                Text("Upcoming").overline()
                            }
                        }

                        if !past.isEmpty {
                            Section {
                                ForEach(past) { row($0).opacity(0.5) }
                                    .onDelete { delete(past, at: $0) }
                            } header: {
                                Text("Past").overline()
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.pageBackground)
            .navigationTitle("Saved")
            .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
            .toolbar {
                if !savedEvents.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) { EditButton() }
                }
            }
        }
    }

    /// Reuses the same row the rest of the app uses, so a saved event looks
    /// like the event you saved.
    private func row(_ saved: SavedEvent) -> some View {
        NavigationLink(value: saved.asEvent) {
            CompactEventRow(event: saved.asEvent, isSaved: true)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func delete(_ source: [SavedEvent], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(source[index])
        }
    }
}
