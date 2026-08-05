//
//  Secrets.swift
//  VT2NH
//
//  Reads API keys from Secrets.plist, which is gitignored and therefore absent
//  from a fresh clone. Every accessor is optional on purpose: a missing key
//  disables one feature, it never crashes or blocks the app.
//
//  Setup:
//    cp FBEventsMockProject/Secrets.example.plist FBEventsMockProject/Secrets.plist
//  then paste in a free key from https://developer.ticketmaster.com
//

import Foundation

enum Secrets {

    /// Placeholder shipped in the example file — treated as "not configured"
    /// so a copied-but-unedited file behaves the same as a missing one.
    private static let placeholder = "YOUR_TICKETMASTER_API_KEY"

    static var ticketmasterAPIKey: String? {
        value(for: "TicketmasterAPIKey")
    }

    private static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data, format: nil) as? [String: Any]
        else { return [:] }
        return plist
    }()

    private static func value(for key: String) -> String? {
        guard let raw = values[key] as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != placeholder else { return nil }
        return trimmed
    }
}
