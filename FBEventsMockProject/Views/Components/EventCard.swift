//
//  EventCard.swift
//  VT2NH
//
//  The row that carries the Discover list. Category stripe on the left, the
//  three facts that matter (what, when, where), and a saved indicator.
//

import SwiftUI

struct EventCard: View {
    let event: Event
    var isSaved: Bool = false
    var distanceText: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Category glyph doubles as the color key used on the map.
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.tint(for: event.category).gradient)
                Image(systemName: event.category.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if isSaved {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.pink)
                            .accessibilityLabel("Saved")
                    }
                }

                Label(event.timeLabel, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .labelStyle(.compact)

                Label(event.venue.name, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .labelStyle(.compact)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    TagPill(text: event.relativeLabel,
                            tint: event.isToday ? .orange : .secondary)

                    if let price = event.priceLabel {
                        TagPill(text: price, tint: event.isFree ? .green : .secondary)
                    }

                    if let distanceText {
                        TagPill(text: distanceText, tint: .secondary)
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .cardSurface()
        .contentShape(.rect)
    }
}

// MARK: - Pill

struct TagPill: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint == .secondary ? Color.secondary : tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((tint == .secondary ? Color.secondary : tint).opacity(0.14),
                        in: .capsule)
    }
}

// MARK: - Tight label

/// Icon and title with less gap than the default, which reads better at
/// subheadline size in a dense list.
private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.font(.caption2)
            configuration.title
        }
    }
}

extension LabelStyle where Self == CompactLabelStyle {
    static var compact: CompactLabelStyle { CompactLabelStyle() }
}

#Preview(traits: .sizeThatFitsLayout) {
    EventCard(
        event: Event(
            id: "preview", name: "Green Mountain Soul Revue",
            summary: "Six-piece soul outfit.", category: .music,
            start: .now.addingTimeInterval(3600), end: .now.addingTimeInterval(14400),
            venue: Venue(name: "Higher Ground Ballroom", address: nil,
                         latitude: 44.4443, longitude: -73.1852),
            town: "Burlington", state: .vermont, ticketURL: nil, priceLabel: "$25"
        ),
        isSaved: true
    )
    .padding()
}
