//
//  EventLogicTests.swift
//  VT2NHTests
//
//  Covers the pure logic the whole app leans on: which town an event belongs
//  to, which time bucket it lands in, and how it labels itself.
//

import Testing
import Foundation
@testable import FBEventsMockProject

// MARK: - Fixtures

private func makeEvent(
    id: String = "test-1",
    name: String = "Test Event",
    category: EventCategory = .music,
    start: Date = .now,
    town: String = "Burlington",
    state: USState = .vermont,
    price: String? = nil
) -> Event {
    Event(id: id,
          name: name,
          summary: "Summary",
          category: category,
          start: start,
          end: start.addingTimeInterval(3600),
          venue: Venue(name: "Venue", address: nil, latitude: 44.0, longitude: -73.0),
          town: town,
          state: state,
          ticketURL: nil,
          priceLabel: price)
}

private func makeTown(_ name: String, _ state: USState) -> AppLocation {
    AppLocation(id: name.lowercased(), town: name, state: state,
                latitude: 44.0, longitude: -73.0, blurb: "",
                wikipediaTitle: name, fallbackCommonsFile: nil)
}

// MARK: - Town matching

@Suite("Event ↔ town matching")
struct TownMatchingTests {

    /// The two Manchesters are the reason state is part of the identity.
    @Test("Same town name in different states does not match")
    func manchesterIsNotManchester() {
        let vermontEvent = makeEvent(town: "Manchester", state: .vermont)
        let newHampshire = makeTown("Manchester", .newHampshire)

        #expect(vermontEvent.matches(newHampshire) == false)
    }

    @Test("Same town and state matches")
    func sameTownMatches() {
        let event = makeEvent(town: "Manchester", state: .vermont)
        #expect(event.matches(makeTown("Manchester", .vermont)))
    }

    @Test("Matching ignores case")
    func matchingIgnoresCase() {
        let event = makeEvent(town: "burlington", state: .vermont)
        #expect(event.matches(makeTown("Burlington", .vermont)))
    }

    /// Both Manchesters exist in the shipped catalog, which is what makes this
    /// a live hazard rather than a hypothetical one.
    @Test("Catalog really does contain a duplicate town name")
    func catalogHasDuplicateTownNames() {
        let names = LocationCatalog.towns.map(\.town)
        let duplicated = Set(names.filter { name in names.filter { $0 == name }.count > 1 })
        #expect(duplicated.contains("Manchester"))
    }
}

// MARK: - Time bucketing

@Suite("Time bucketing")
struct TimeBucketTests {

    @Test("Today is bucketed as today")
    func todayBucket() {
        #expect(TimeBucket.bucket(for: .now) == .today)
    }

    @Test("Tomorrow is bucketed as tomorrow")
    func tomorrowBucket() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        #expect(TimeBucket.bucket(for: tomorrow) == .tomorrow)
    }

    @Test("Three days out is this week")
    func thisWeekBucket() {
        let soon = Calendar.current.date(byAdding: .day, value: 3, to: .now)!
        #expect(TimeBucket.bucket(for: soon) == .thisWeek)
    }

    @Test("Twenty days out is later")
    func laterBucket() {
        let far = Calendar.current.date(byAdding: .day, value: 20, to: .now)!
        #expect(TimeBucket.bucket(for: far) == .later)
    }
}

// MARK: - Labels

@Suite("Event labelling")
struct EventLabelTests {

    /// Regression: a past event used to render a bare weekday, reading as
    /// though it were still upcoming.
    @Test("Past events show an absolute date, not a weekday")
    func pastEventShowsAbsoluteDate() {
        let lastWeek = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        let label = makeEvent(start: lastWeek).relativeLabel

        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday",
                        "Friday", "Saturday", "Sunday"]
        #expect(weekdays.contains(label) == false)
    }

    @Test("Today reads as Today")
    func todayLabel() {
        #expect(makeEvent(start: .now).relativeLabel == "Today")
    }

    @Test("Far-future events count the days")
    func farFutureLabel() {
        let far = Calendar.current.date(byAdding: .day, value: 12, to: .now)!
        #expect(makeEvent(start: far).relativeLabel.hasPrefix("In "))
    }

    @Test("Free detection", arguments: [
        ("Free", true), ("free", true), ("Free entry", true),
        ("$25", false), ("Donation", false)
    ])
    func freeDetection(price: String, expected: Bool) {
        #expect(makeEvent(price: price).isFree == expected)
    }

    @Test("An event with no price is not free")
    func noPriceIsNotFree() {
        #expect(makeEvent(price: nil).isFree == false)
    }
}
