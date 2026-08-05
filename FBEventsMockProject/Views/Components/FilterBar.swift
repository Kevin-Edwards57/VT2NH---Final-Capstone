//
//  FilterBar.swift
//  VT2NH
//
//  Horizontal category chips plus a free-only toggle. Selection lives in the
//  store, so the map and the list stay in agreement.
//

import SwiftUI

struct FilterBar: View {
    @Bindable var store: EventStore

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Chip(title: "Free",
                     symbol: "tag.fill",
                     tint: .green,
                     isOn: store.freeOnly) {
                    withAnimation(.snappy) { store.freeOnly.toggle() }
                }

                Divider().frame(height: 22)

                ForEach(EventCategory.allCases) { category in
                    Chip(title: category.title,
                         symbol: category.symbol,
                         tint: Theme.tint(for: category),
                         isOn: store.selectedCategories.contains(category)) {
                        withAnimation(.snappy) { store.toggle(category) }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Chip

private struct Chip: View {
    let title: String
    let symbol: String
    let tint: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.caption2)
                Text(title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isOn ? .white : Color.primary)
            .background {
                if isOn {
                    Capsule().fill(tint.gradient)
                } else {
                    Capsule().fill(Color(.secondarySystemGroupedBackground))
                    Capsule().strokeBorder(Color(.separator), lineWidth: 0.5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}
