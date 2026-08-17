//
//  EventProviding.swift
//  VT2NH
//
//  One protocol, two sources. The app talks to this and never to a specific
//  vendor, which is what lets the bundled feed and a live API coexist.
//

import Foundation

protocol EventProviding: Sendable {
    /// Human-readable source name, surfaced in the Discover footer.
    var attribution: String { get }
    func events(near location: AppLocation, radiusMiles: Int) async throws -> [Event]
}

enum EventProviderError: LocalizedError {
    case badResponse(status: Int)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .badResponse(let status):
            "The events service returned an error (HTTP \(status))."
        case .missingAPIKey:
            "No Ticketmaster API key configured."
        }
    }
}
