//
//  WikipediaService.swift
//  VT2NH
//
//  Town photos, summaries, and article links from Wikipedia and Wikimedia
//  Commons. No API key and no account — the only requirement Wikimedia places
//  on clients is a descriptive User-Agent, which is set below.
//
//  Photos are Commons-licensed (mostly CC BY-SA). The API also returns the
//  photographer and license, and the app displays both, which is what keeps
//  reuse compliant when this ships on the App Store.
//

import Foundation

struct TownPhoto: Sendable, Equatable {
    let url: URL
    let credit: String?
    let license: String?

    /// "Photo: Ken Gallager · CC BY-SA 3.0"
    var attribution: String? {
        switch (credit, license) {
        case let (credit?, license?): "Photo: \(credit) · \(license)"
        case let (credit?, nil):      "Photo: \(credit)"
        case let (nil, license?):     "Photo · \(license)"
        default:                       nil
        }
    }
}

struct TownProfile: Sendable, Equatable {
    let summary: String
    let articleURL: URL?
    let photo: TownPhoto?
}

actor WikipediaService {
    static let shared = WikipediaService()

    private var cache: [String: TownProfile] = [:]
    private var fileCache: [String: TownPhoto] = [:]
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        // Wikimedia asks that clients identify themselves.
        configuration.httpAdditionalHeaders = [
            "User-Agent": "VT2NH/1.0 (iOS portfolio app; contact via GitHub)"
        ]
        // Photos are static; let the URL cache do real work.
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
    }

    func profile(for town: AppLocation) async -> TownProfile? {
        if let cached = cache[town.id] { return cached }

        guard let summary = await fetchSummary(title: town.wikipediaTitle) else { return nil }

        // Wikipedia's lead image for small villages is often a locator map
        // rather than a photograph. Fall back to a curated Commons file.
        var photo = summary.photo
        if photo == nil || Self.looksLikeMap(photo!.url) {
            if let file = town.fallbackCommonsFile {
                photo = await fetchCommonsPhoto(file: file)
            } else if photo != nil, Self.looksLikeMap(photo!.url) {
                photo = nil
            }
        } else if let existing = photo {
            // Enrich the lead image with its credit and license.
            photo = await enrich(existing)
        }

        let profile = TownProfile(summary: summary.summary,
                                  articleURL: summary.articleURL,
                                  photo: photo)
        cache[town.id] = profile
        return profile
    }

    /// Fetches a specific Commons file with its credit and license. Used for
    /// the state hero cards, where the Wikipedia lead image is a flag.
    func photo(commonsFile file: String) async -> TownPhoto? {
        if let cached = fileCache[file] { return cached }
        guard let photo = await fetchCommonsPhoto(file: file) else { return nil }
        fileCache[file] = photo
        return photo
    }

    // MARK: Summary endpoint

    private func fetchSummary(title: String) async -> TownProfile? {
        let slug = title.replacingOccurrences(of: " ", with: "_")
        guard let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)"),
              let (data, response) = try? await session.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let payload = try? JSONDecoder().decode(SummaryResponse.self, from: data)
        else { return nil }

        let imageURL = payload.originalimage?.source ?? payload.thumbnail?.source
        return TownProfile(
            summary: payload.extract ?? "",
            articleURL: payload.contentUrls?.desktop?.page.flatMap(URL.init(string:)),
            photo: imageURL.flatMap(URL.init(string:)).map {
                TownPhoto(url: $0, credit: nil, license: nil)
            }
        )
    }

    // MARK: Commons

    /// Looks up a Commons file by title and returns a display-sized URL plus credit.
    private func fetchCommonsPhoto(file: String) async -> TownPhoto? {
        var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
        components.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "titles", value: file),
            .init(name: "prop", value: "imageinfo"),
            .init(name: "iiprop", value: "extmetadata|url"),
            .init(name: "iiurlwidth", value: "1400"),
            .init(name: "format", value: "json")
        ]
        return await commonsPhoto(from: components)
    }

    /// Adds credit/license to a photo we already have a URL for.
    private func enrich(_ photo: TownPhoto) async -> TownPhoto {
        guard let filename = Self.commonsFilename(from: photo.url) else { return photo }
        var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
        components.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "titles", value: "File:\(filename)"),
            .init(name: "prop", value: "imageinfo"),
            .init(name: "iiprop", value: "extmetadata"),
            .init(name: "format", value: "json")
        ]
        guard let credited = await commonsPhoto(from: components) else { return photo }
        // Keep the original URL — only the metadata is wanted here.
        return TownPhoto(url: photo.url, credit: credited.credit, license: credited.license)
    }

    private func commonsPhoto(from components: URLComponents) async -> TownPhoto? {
        guard let url = components.url,
              let (data, response) = try? await session.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let payload = try? JSONDecoder().decode(CommonsResponse.self, from: data),
              let info = payload.query?.pages?.values.compactMap({ $0.imageinfo?.first }).first
        else { return nil }

        let metadata = info.extmetadata
        let imageURL = (info.thumburl ?? info.url).flatMap(URL.init(string:))
        guard let imageURL else { return nil }

        // Bind first: `.map` on a String would iterate its characters.
        let rawCredit: String? = metadata?.artist?.value
        return TownPhoto(
            url: imageURL,
            credit: rawCredit.map(Self.strippingHTML),
            license: metadata?.licenseShortName?.value
        )
    }

    // MARK: Helpers

    /// Wikipedia serves locator maps as SVG-derived PNGs with telltale names.
    private static func looksLikeMap(_ url: URL) -> Bool {
        let text = url.absoluteString.lowercased()
        return text.contains(".svg")
            || text.contains("highlighted")
            || text.contains("locator")
            || text.contains("_map")
    }

    private static func commonsFilename(from url: URL) -> String? {
        // .../commons/thumb/0/03/HanoverNHMainStreet.jpg/1400px-....jpg
        let parts = url.pathComponents.filter { $0 != "/" }
        guard let candidate = parts.last(where: { component in
            [".jpg", ".jpeg", ".png"].contains { component.lowercased().hasSuffix($0) }
                && !component.lowercased().hasPrefix("thumb")
        }) else { return nil }
        // Prefer the original filename over the resized one.
        let original = parts.first { $0.lowercased().hasSuffix(".jpg")
            || $0.lowercased().hasSuffix(".jpeg")
            || $0.lowercased().hasSuffix(".png") }
        return (original ?? candidate).removingPercentEncoding ?? original ?? candidate
    }

    private static func strippingHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "(talk)", with: "")
            .replacingOccurrences(of: "(Uploads)", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Wire formats

private struct SummaryResponse: Decodable {
    let extract: String?
    let thumbnail: Image?
    let originalimage: Image?
    let contentUrls: ContentURLs?

    enum CodingKeys: String, CodingKey {
        case extract, thumbnail, originalimage
        case contentUrls = "content_urls"
    }

    struct Image: Decodable { let source: String }
    struct ContentURLs: Decodable {
        let desktop: Desktop?
        struct Desktop: Decodable { let page: String? }
    }
}

private struct CommonsResponse: Decodable {
    let query: Query?

    struct Query: Decodable {
        let pages: [String: Page]?
    }

    struct Page: Decodable {
        let imageinfo: [ImageInfo]?
    }

    struct ImageInfo: Decodable {
        let url: String?
        let thumburl: String?
        let extmetadata: ExtMetadata?
    }

    struct ExtMetadata: Decodable {
        let artist: Value?
        let licenseShortName: Value?

        enum CodingKeys: String, CodingKey {
            case artist = "Artist"
            case licenseShortName = "LicenseShortName"
        }

        struct Value: Decodable { let value: String }
    }
}
