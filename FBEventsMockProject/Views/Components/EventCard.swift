//
//  EventCard.swift
//  VT2NH
//
//  The row that carries the Discover list: a photo banner with the category
//  overline and title laid over it, then the practical details beneath.
//

import SwiftUI

struct EventCard: View {
    let event: Event
    var isSaved: Bool = false
    var distanceText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            ZStack(alignment: .bottomLeading) {
                EventImageView(event: event, height: 150)

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.category.title)
                        .overline(.white.opacity(0.9))

                    Text(event.name)
                        .font(.display(.title3))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .padding(12)

                // Category glyph, top-trailing, so the color key survives even
                // when the photo behind it is busy.
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: event.category.symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(Theme.tint(for: event.category).gradient, in: .circle)
                            .padding(10)
                    }
                    Spacer()
                }

                if isSaved {
                    VStack {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundStyle(.pink)
                                .padding(7)
                                .background(.ultraThinMaterial, in: .circle)
                                .padding(10)
                                .accessibilityLabel("Saved")
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Label(event.timeLabel, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .labelStyle(.compact)

                Label("\(event.venue.name) · \(event.town), \(event.state.abbreviation)",
                      systemImage: "mappin.and.ellipse")
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
                .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
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
