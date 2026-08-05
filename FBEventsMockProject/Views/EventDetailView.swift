//
//  EventDetailView.swift
//  VT2NH
//
//  Full detail for one event: what it is, when, the forecast for that day at
//  those coordinates, a map, and the three things a person actually wants to
//  do — save it, add it to their calendar, get directions.
//

import SwiftUI
import MapKit
import SwiftData
import EventKit

struct EventDetailView: View {
    let event: Event

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var savedEvents: [SavedEvent]

    @State private var forecast: DayForecast?
    @State private var calendarMessage: String?
    @State private var showingCalendarAlert = false

    private var savedRecord: SavedEvent? {
        savedEvents.first { $0.eventID == event.id }
    }
    private var isSaved: Bool { savedRecord != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                EventImageView(event: event, height: 230, showsAttribution: true)
                    .clipShape(.rect(cornerRadius: Theme.cardCorner))

                heroHeader
                detailRows
                if let forecast { forecastCard(forecast) }
                mapCard
                actions
            }
            .padding()
        }
        .background(Theme.pageBackground)
        .navigationTitle(event.town)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleSaved()
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .foregroundStyle(isSaved ? .pink : .primary)
                        .symbolEffect(.bounce, value: isSaved)
                }
                .accessibilityLabel(isSaved ? "Remove from saved" : "Save event")
            }
        }
        .task {
            forecast = await WeatherService.shared.forecast(for: event)
        }
        .alert("Calendar", isPresented: $showingCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarMessage ?? "")
        }
    }

    // MARK: Header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label(event.category.title, systemImage: event.category.symbol)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.tint(for: event.category).gradient, in: .capsule)
                    .foregroundStyle(.white)

                TagPill(text: event.relativeLabel,
                        tint: event.isToday ? .orange : .secondary)

                if let price = event.priceLabel {
                    TagPill(text: price, tint: event.isFree ? .green : .secondary)
                }
            }

            Text(event.name)
                .font(.display(34))

            Text(event.summary)
                .font(.body)
                .italic()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Facts

    private var detailRows: some View {
        VStack(spacing: 0) {
            DetailRow(symbol: "calendar",
                      title: "When",
                      value: event.fullDateLabel)
            Divider().padding(.leading, 44)
            DetailRow(symbol: "mappin.and.ellipse",
                      title: "Where",
                      value: event.venue.name,
                      secondary: event.venue.address)
            Divider().padding(.leading, 44)
            DetailRow(symbol: "building.2",
                      title: "Town",
                      value: "\(event.town), \(event.state.abbreviation)")
        }
        .padding(.vertical, 4)
        .cardSurface()
    }

    // MARK: Forecast

    private func forecastCard(_ forecast: DayForecast) -> some View {
        HStack(spacing: 14) {
            Image(systemName: forecast.symbol)
                .font(.system(size: 32))
                .symbolRenderingMode(.multicolor)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Forecast for \(event.dayLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(forecast.summary) · \(forecast.highF)° / \(forecast.lowF)°")
                    .font(.headline)
                if forecast.precipitationChance > 0 {
                    Text("\(forecast.precipitationChance)% chance of precipitation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .cardSurface()
    }

    // MARK: Map

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: event.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
            )), interactionModes: [.pan, .zoom]) {
                Marker(event.venue.name, systemImage: event.category.symbol,
                       coordinate: event.coordinate)
                    .tint(Theme.tint(for: event.category))
            }
            .frame(height: 180)
            .allowsHitTesting(false)

            Button {
                openInMaps()
            } label: {
                Label("Get Directions", systemImage: "car.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .cardSurface()
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                toggleSaved()
            } label: {
                Label(isSaved ? "Saved" : "Save Event",
                      systemImage: isSaved ? "checkmark.circle.fill" : "heart.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isSaved ? .gray : .pink)
            .controlSize(.large)

            Button {
                Task { await addToCalendar() }
            } label: {
                Label("Add to Calendar", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if let url = event.ticketURL {
                Link(destination: url) {
                    Label("Event Website", systemImage: "safari.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    // MARK: Behavior

    private func toggleSaved() {
        withAnimation(.snappy) {
            if let savedRecord {
                modelContext.delete(savedRecord)
            } else {
                modelContext.insert(SavedEvent(event: event))
            }
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: event.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = event.venue.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    /// Writes the event into the user's default calendar after asking for
    /// permission. Uses the iOS 17+ write-only request, which is the narrowest
    /// access that does the job.
    private func addToCalendar() async {
        let store = EKEventStore()
        do {
            guard try await store.requestWriteOnlyAccessToEvents() else {
                calendarMessage = "Calendar access was declined. You can change this in Settings."
                showingCalendarAlert = true
                return
            }

            let calendarEvent = EKEvent(eventStore: store)
            calendarEvent.title = event.name
            calendarEvent.startDate = event.start
            calendarEvent.endDate = event.end ?? event.start.addingTimeInterval(7200)
            calendarEvent.location = "\(event.venue.name), \(event.town), \(event.state.abbreviation)"
            calendarEvent.notes = event.summary
            calendarEvent.url = event.ticketURL
            calendarEvent.calendar = store.defaultCalendarForNewEvents

            try store.save(calendarEvent, span: .thisEvent)
            calendarMessage = "\(event.name) was added to your calendar."
        } catch {
            calendarMessage = "Could not add the event: \(error.localizedDescription)"
        }
        showingCalendarAlert = true
    }
}

// MARK: - Row

struct DetailRow: View {
    let symbol: String
    let title: String
    let value: String
    var secondary: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.medium))
                if let secondary {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
