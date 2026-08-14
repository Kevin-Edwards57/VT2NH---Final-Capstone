//
//  CompactEventRow.swift
//  VT2NH
//
//  The dense counterpart to EventCard. A section leads with one full-width
//  hero and lists the rest as these, so a 105-event feed has rhythm and stays
//  scannable instead of being 105 identical photo blocks.
//

import SwiftUI

struct CompactEventRow: View {
    let event: Event
    var isSaved: Bool = false
    var showsTown: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            EventImageView(event: event, height: 76)
                .frame(width: 76)
                .clipShape(.rect(cornerRadius: 10))
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: event.category.symbol)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Theme.tint(for: event.category), in: .circle)
                        .padding(4)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.category.title)
                    .overline(Theme.tint(for: event.category))

                Text(event.name)
                    .font(.display(.subheadline))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(locationLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    TagPill(text: event.relativeLabel,
                            tint: event.isToday ? .orange : .secondary)
                    if let price = event.priceLabel {
                        TagPill(text: price, tint: event.isFree ? .green : .secondary)
                    }
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 0)

            if isSaved {
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.pink)
                    .accessibilityLabel("Saved")
            }
        }
        .padding(10)
        .cardSurface()
        .contentShape(.rect)
    }

    private var locationLine: String {
        let when = event.start.formatted(date: .omitted, time: .shortened)
        return showsTown
            ? "\(when) · \(event.venue.name), \(event.town)"
            : "\(when) · \(event.venue.name)"
    }
}
