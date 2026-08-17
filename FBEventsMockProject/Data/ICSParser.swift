//
//  ICSParser.swift
//  VT2NH
//
//  A small iCalendar (RFC 5545) reader — enough of the spec to turn a public
//  library or venue calendar into events, and no more.
//
//  iCalendar is a plain text format served over HTTP. There is no API key, no
//  account, and no quota: a published .ics exists to be subscribed to. That is
//  what makes this the cheapest possible source of genuinely real event data.
//

import Foundation

struct ICSEvent {
    var uid: String?
    var summary: String?
    var description: String?
    var location: String?
    var url: String?
    var start: Date?
    var end: Date?
    var isAllDay = false
}

enum ICSParser {

    static func parse(_ text: String) -> [ICSEvent] {
        var events: [ICSEvent] = []
        var current: ICSEvent?

        for line in unfold(text) {
            if line.hasPrefix("BEGIN:VEVENT") {
                current = ICSEvent()
                continue
            }
            if line.hasPrefix("END:VEVENT") {
                if let event = current { events.append(event) }
                current = nil
                continue
            }
            guard current != nil, let (name, params, value) = splitProperty(line) else { continue }

            switch name {
            case "UID":         current?.uid = value
            case "SUMMARY":     current?.summary = unescape(value)
            case "DESCRIPTION": current?.description = unescape(value)
            case "LOCATION":    current?.location = unescape(value)
            case "URL":         current?.url = value
            case "DTSTART":
                current?.start = date(from: value, params: params)
                current?.isAllDay = params["VALUE"] == "DATE"
            case "DTEND":
                current?.end = date(from: value, params: params)
            default:
                break
            }
        }
        return events
    }

    // MARK: Line handling

    /// iCalendar wraps long lines: a continuation begins with a space or tab
    /// and belongs to the previous line. Parsing without unfolding silently
    /// truncates any title or address longer than 75 octets.
    private static func unfold(_ text: String) -> [String] {
        var out: [String] = []
        for raw in text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n") {
            if let first = raw.first, first == " " || first == "\t" {
                let continuation = String(raw.dropFirst())
                if out.isEmpty { out.append(continuation) } else { out[out.count - 1] += continuation }
            } else {
                out.append(raw)
            }
        }
        return out
    }

    /// Splits `NAME;PARAM=VALUE;OTHER=X:the value` into its three parts.
    private static func splitProperty(_ line: String) -> (String, [String: String], String)? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let head = String(line[line.startIndex..<colon])
        let value = String(line[line.index(after: colon)...])

        let pieces = head.components(separatedBy: ";")
        guard let name = pieces.first?.uppercased() else { return nil }

        var params: [String: String] = [:]
        for piece in pieces.dropFirst() {
            let kv = piece.components(separatedBy: "=")
            if kv.count == 2 { params[kv[0].uppercased()] = kv[1] }
        }
        return (name, params, value)
    }

    private static func unescape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Dates
    //
    // Three shapes appear in the wild:
    //   DTSTART:20260817T120000Z                        — UTC
    //   DTSTART;TZID=America/New_York:20260817T120000   — a named zone
    //   DTSTART;VALUE=DATE:20260817                     — all day

    static func date(from value: String, params: [String: String]) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if value.hasSuffix("Z") {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: value)
        }

        if params["VALUE"] == "DATE" || value.count == 8 {
            formatter.dateFormat = "yyyyMMdd"
            formatter.timeZone = TimeZone(identifier: params["TZID"] ?? "") ?? .current
            // An all-day entry gets a sensible hour so it sorts among timed events.
            guard let day = formatter.date(from: value) else { return nil }
            return Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: day)
        }

        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = TimeZone(identifier: params["TZID"] ?? "") ?? .current
        return formatter.date(from: value)
    }
}
