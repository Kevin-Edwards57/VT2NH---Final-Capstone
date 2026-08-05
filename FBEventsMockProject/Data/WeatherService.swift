//
//  WeatherService.swift
//  VT2NH
//
//  Forecast for an event's day at an event's coordinates, via Open-Meteo.
//  No API key, no signup, no cost — 10,000 calls/day on the free tier.
//  Data licensed CC BY 4.0; attribution is shown on the event detail screen.
//
//  Open-Meteo forecasts run about 16 days out. Anything further returns nil and
//  the UI simply omits the forecast row rather than showing a guess.
//

import Foundation
import CoreLocation

struct DayForecast: Sendable, Equatable {
    let highF: Int
    let lowF: Int
    let precipitationChance: Int
    let code: WeatherCode

    var summary: String { code.description }
    var symbol: String { code.symbol }
}

/// WMO weather interpretation codes, which is what Open-Meteo returns.
enum WeatherCode: Int, Sendable {
    case clear = 0, mainlyClear = 1, partlyCloudy = 2, overcast = 3
    case fog = 45, rimeFog = 48
    case drizzleLight = 51, drizzle = 53, drizzleHeavy = 55
    case rainLight = 61, rain = 63, rainHeavy = 65
    case snowLight = 71, snow = 73, snowHeavy = 75
    case showers = 80, showersHeavy = 81, showersViolent = 82
    case thunderstorm = 95, thunderstormHail = 96

    var description: String {
        switch self {
        case .clear, .mainlyClear:              "Clear"
        case .partlyCloudy:                      "Partly cloudy"
        case .overcast:                          "Overcast"
        case .fog, .rimeFog:                     "Fog"
        case .drizzleLight, .drizzle, .drizzleHeavy: "Drizzle"
        case .rainLight, .rain:                  "Rain"
        case .rainHeavy:                         "Heavy rain"
        case .snowLight, .snow:                  "Snow"
        case .snowHeavy:                         "Heavy snow"
        case .showers, .showersHeavy, .showersViolent: "Showers"
        case .thunderstorm, .thunderstormHail:   "Thunderstorms"
        }
    }

    var symbol: String {
        switch self {
        case .clear, .mainlyClear:               "sun.max.fill"
        case .partlyCloudy:                       "cloud.sun.fill"
        case .overcast:                           "cloud.fill"
        case .fog, .rimeFog:                      "cloud.fog.fill"
        case .drizzleLight, .drizzle, .drizzleHeavy: "cloud.drizzle.fill"
        case .rainLight, .rain, .rainHeavy:       "cloud.rain.fill"
        case .snowLight, .snow, .snowHeavy:       "snowflake"
        case .showers, .showersHeavy, .showersViolent: "cloud.heavyrain.fill"
        case .thunderstorm, .thunderstormHail:    "cloud.bolt.rain.fill"
        }
    }
}

actor WeatherService {
    static let shared = WeatherService()

    /// Keyed by coordinate + day so scrolling a list never refetches the same cell.
    private var cache: [String: DayForecast] = [:]

    func forecast(for event: Event) async -> DayForecast? {
        let dayKey = Self.dayFormatter.string(from: event.start)
        let cacheKey = "\(event.venue.latitude),\(event.venue.longitude)@\(dayKey)"
        if let cached = cache[cacheKey] { return cached }

        // Outside the forecast horizon there is nothing honest to show.
        let daysOut = Calendar.current.dateComponents([.day], from: .now, to: event.start).day ?? 0
        guard (0...15).contains(daysOut) else { return nil }

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(event.venue.latitude)),
            .init(name: "longitude", value: String(event.venue.longitude)),
            .init(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            .init(name: "temperature_unit", value: "fahrenheit"),
            .init(name: "timezone", value: "auto"),
            .init(name: "start_date", value: dayKey),
            .init(name: "end_date", value: dayKey)
        ]

        guard let url = components.url,
              let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let payload = try? JSONDecoder().decode(OpenMeteoResponse.self, from: data),
              let forecast = payload.firstDay
        else { return nil }

        cache[cacheKey] = forecast
        return forecast
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Wire format

private struct OpenMeteoResponse: Decodable {
    let daily: Daily

    struct Daily: Decodable {
        let weatherCode: [Int]
        let temperatureMax: [Double]
        let temperatureMin: [Double]
        let precipitationProbabilityMax: [Int?]?

        enum CodingKeys: String, CodingKey {
            case weatherCode = "weather_code"
            case temperatureMax = "temperature_2m_max"
            case temperatureMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
        }
    }

    var firstDay: DayForecast? {
        guard let code = daily.weatherCode.first,
              let high = daily.temperatureMax.first,
              let low = daily.temperatureMin.first
        else { return nil }

        return DayForecast(
            highF: Int(high.rounded()),
            lowF: Int(low.rounded()),
            precipitationChance: daily.precipitationProbabilityMax?.first.flatMap { $0 } ?? 0,
            code: WeatherCode(rawValue: code) ?? .partlyCloudy
        )
    }
}
