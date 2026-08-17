//
//  DeduplicationTests.swift
//  VT2NHTests
//
//  Locks down the merge identity. This is the logic most likely to silently
//  destroy data if it regresses: too loose and legitimate events disappear,
//  too strict and the same show appears twice from two providers.
//

import Testing
import Foundation
@testable import FBEventsMockProject

private func event(
    id: String,
    name: String,
    town: String,
    state: USState = .vermont,
    daysFromNow: Int = 0,
    hour: Int = 19
) -> Event {
    let day = Calendar.current.date(byAdding: .day, value: daysFromNow, to: .now)!
    let start = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
    return Event(id: id, name: name, summary: "", category: .food,
                 start: start, end: nil,
                 venue: Venue(name: "Venue", address: nil, latitude: 44, longitude: -73),
                 town: town, state: state, ticketURL: nil, priceLabel: nil)
}

@Suite("Event deduplication")
struct DeduplicationTests {

    /// The bug this key was widened to fix. Two towns, one Saturday, same
    /// event name — both must survive.
    @Test("Identically named events in different towns are both kept")
    func differentTownsBothSurvive() {
        let result = EventStore.deduplicated([
            event(id: "a", name: "Farmers Market", town: "Bennington"),
            event(id: "b", name: "Farmers Market", town: "Keene", state: .newHampshire)
        ])
        #expect(result.count == 2)
    }

    /// Town names are not unique either.
    @Test("Same town name in different states is not a duplicate")
    func sameTownNameDifferentStates() {
        let result = EventStore.deduplicated([
            event(id: "a", name: "Summer Concert", town: "Manchester", state: .vermont),
            event(id: "b", name: "Summer Concert", town: "Manchester", state: .newHampshire)
        ])
        #expect(result.count == 2)
    }

    /// The behaviour deduplication exists for: one provider's copy wins.
    @Test("The same event from two providers collapses to one")
    func sameEventCollapses() {
        let result = EventStore.deduplicated([
            event(id: "bundled-1", name: "Green Mountain Soul Revue", town: "Burlington"),
            event(id: "tm-xyz", name: "Green Mountain Soul Revue", town: "Burlington", hour: 20)
        ])
        #expect(result.count == 1)
        // First one wins, so the bundled copy is retained.
        #expect(result.first?.id == "bundled-1")
    }

    @Test("Same name in the same town on different days are both kept")
    func differentDaysBothSurvive() {
        let result = EventStore.deduplicated([
            event(id: "a", name: "Trivia Night", town: "Burlington", daysFromNow: 0),
            event(id: "b", name: "Trivia Night", town: "Burlington", daysFromNow: 1)
        ])
        #expect(result.count == 2)
    }

    @Test("Casing and padding differences still collapse")
    func normalizationCollapsesFormatting() {
        let result = EventStore.deduplicated([
            event(id: "a", name: "Jazz Night", town: "Burlington"),
            event(id: "b", name: "  JAZZ NIGHT  ", town: " burlington ")
        ])
        #expect(result.count == 1)
    }

    @Test("Accented and unaccented spellings collapse")
    func diacriticFoldingCollapses() {
        let result = EventStore.deduplicated([
            event(id: "a", name: "Dvořák Quartet", town: "Burlington"),
            event(id: "b", name: "Dvorak Quartet", town: "Burlington")
        ])
        #expect(result.count == 1)
    }

    @Test("Deduplication preserves input order")
    func orderPreserved() {
        let result = EventStore.deduplicated([
            event(id: "first", name: "A", town: "Barre"),
            event(id: "second", name: "B", town: "Barre"),
            event(id: "third", name: "C", town: "Barre")
        ])
        #expect(result.map(\.id) == ["first", "second", "third"])
    }

    @Test("An empty list stays empty")
    func emptyStaysEmpty() {
        #expect(EventStore.deduplicated([]).isEmpty)
    }

    @Test("Normalization is locale-independent and folds case")
    func normalizationBehaviour() {
        #expect(EventStore.normalized("  Café  ") == EventStore.normalized("CAFE"))
    }
}
