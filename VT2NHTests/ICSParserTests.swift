//
//  ICSParserTests.swift
//  VT2NHTests
//
//  The parser reads third-party feeds we do not control, so its edge cases are
//  the ones most likely to break in production: folded lines, escaped commas,
//  and three different date encodings.
//

import Testing
import Foundation
@testable import FBEventsMockProject

@Suite("iCalendar parsing")
struct ICSParserTests {

    @Test("Parses a minimal event")
    func minimalEvent() {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        UID:abc-123
        SUMMARY:Story Time
        DTSTART;TZID=America/New_York:20260817T103000
        LOCATION:Kellogg-Hubbard Library\\, 135 Main Street\\, Montpelier\\, VT
        END:VEVENT
        END:VCALENDAR
        """
        let events = ICSParser.parse(ics)

        #expect(events.count == 1)
        #expect(events.first?.summary == "Story Time")
        #expect(events.first?.uid == "abc-123")
        // Escaped commas must come back as real ones.
        #expect(events.first?.location?.contains("Library, 135 Main Street") == true)
    }

    /// iCalendar wraps at 75 octets; a continuation line starts with a space.
    /// Without unfolding, long titles are silently truncated.
    @Test("Unfolds wrapped lines")
    func unfoldsLongLines() {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:An extremely long event title that the calendar server has wrap
         ped onto a second line
        DTSTART:20260817T120000Z
        END:VEVENT
        END:VCALENDAR
        """
        #expect(ICSParser.parse(ics).first?.summary
                == "An extremely long event title that the calendar server has wrapped onto a second line")
    }

    @Test("Reads UTC timestamps")
    func utcDates() {
        let date = ICSParser.date(from: "20260817T120000Z", params: [:])
        let parts = Calendar(identifier: .gregorian)
        var utc = parts
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        #expect(utc.component(.hour, from: try! #require(date)) == 12)
    }

    @Test("Reads all-day dates")
    func allDayDates() {
        let date = ICSParser.date(from: "20260817", params: ["VALUE": "DATE"])
        #expect(date != nil)
    }

    @Test("Handles multiple events in one feed")
    func multipleEvents() {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:First
        DTSTART:20260817T120000Z
        END:VEVENT
        BEGIN:VEVENT
        SUMMARY:Second
        DTSTART:20260818T120000Z
        END:VEVENT
        END:VCALENDAR
        """
        #expect(ICSParser.parse(ics).map(\.summary) == ["First", "Second"])
    }

    @Test("Ignores calendar-level properties outside events")
    func ignoresNonEventProperties() {
        let ics = """
        BEGIN:VCALENDAR
        PRODID:-//Some Vendor//EN
        X-WR-CALNAME:Library Events
        BEGIN:VEVENT
        SUMMARY:Real Event
        DTSTART:20260817T120000Z
        END:VEVENT
        END:VCALENDAR
        """
        let events = ICSParser.parse(ics)
        #expect(events.count == 1)
        #expect(events.first?.summary == "Real Event")
    }

    @Test("Empty or junk input yields no events")
    func junkInput() {
        #expect(ICSParser.parse("").isEmpty)
        #expect(ICSParser.parse("<html>not a calendar</html>").isEmpty)
    }

    @Test("Escaped newlines in descriptions are decoded")
    func escapedNewlines() {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Talk
        DESCRIPTION:First line\\nSecond line
        DTSTART:20260817T120000Z
        END:VEVENT
        END:VCALENDAR
        """
        #expect(ICSParser.parse(ics).first?.description?.contains("\n") == true)
    }
}

@Suite("Calendar feed categorisation")
struct CalendarCategoryTests {

    @Test("Infers a category from the title", arguments: [
        ("Toddler Story Time", EventCategory.family),
        ("Lego Club", EventCategory.family),
        ("Summer Concert on the Lawn", EventCategory.music),
        ("Author Talk: New Novel", EventCategory.arts),
        ("Gentle Yoga", EventCategory.sports),
        ("Birding Walk", EventCategory.outdoors),
        ("Trivia Night", EventCategory.nightlife),
        ("Selectboard Meeting", EventCategory.community)
    ])
    func categoryInference(title: String, expected: EventCategory) {
        #expect(CalendarFeedProvider.category(for: title) == expected)
    }

    @Test("Every registered feed points at a town in the catalog")
    func feedsMapToCatalogTowns() {
        for feed in CalendarFeed.all {
            #expect(LocationCatalog.towns.contains { $0.id == feed.townID },
                    "feed \(feed.venueName) references unknown town id \(feed.townID)")
        }
    }
}
