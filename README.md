# VT2NH

An iOS event-discovery app for Vermont and New Hampshire. Browse what's happening
across ten towns, filter by category, see it on a map, check the forecast for the
day of the event, and save what you want to go to.

Built with SwiftUI, SwiftData, MapKit, and EventKit. Every data source is free
and requires no paid plan.

---

## Screens

| Discover | Towns | Map | Saved |
|---|---|---|---|
| Search and filter events, grouped into Today / Tomorrow / This Week / Later | Photo cards for all ten towns, each with a Wikipedia summary and article link | Every event as a category-tinted pin across both states | Bookmarked events, split into upcoming and past |

---

## Data sources

All free. No paid tier, no credit card.

| Source | What it provides | Key required | Limits |
|---|---|---|---|
| **Bundled feed** (`Data/events.json`) | 35 sample events across ten towns | No | None — works offline |
| **[Ticketmaster Discovery](https://developer.ticketmaster.com)** | Real ticketed events near a town | Yes, free | 5,000 req/day |
| **[Open-Meteo](https://open-meteo.com)** | Forecast for each event's date and coordinates | **No** | 10,000 req/day |
| **[Wikipedia REST](https://en.wikipedia.org/api/rest_v1/)** / **Wikimedia Commons** | Town photos, summaries, article links | **No** | Fair use, needs a User-Agent |
| **MapKit / EventKit / SwiftData** | Maps, calendar writes, persistence | No | Built into iOS |

The bundled feed stores **day offsets rather than absolute dates**, so the
calendar resolves against today every launch and never shows a stale demo.

### Live event data (optional)

The app runs fully without this. To turn on live Ticketmaster events:

```bash
cp FBEventsMockProject/Secrets.example.plist FBEventsMockProject/Secrets.plist
```

Paste a free key from [developer.ticketmaster.com](https://developer.ticketmaster.com)
into `Secrets.plist`. That file is gitignored. Live results are merged with the
bundled feed and deduplicated by name and date.

Ticketmaster covers the larger venues — the Flynn, Higher Ground, the Paramount,
Lebanon Opera House. It does not carry small-town markets and community events,
which is why the bundled feed stays in the mix rather than being replaced.

---

## Running it

Requires Xcode 16+ and iOS 18.2+.

```bash
open FBEventsMockProject.xcodeproj
```

Pick any simulator and run. No configuration needed.

---

## Architecture

```
Models/     Event, EventCategory, Venue, AppLocation, SavedEvent (@Model)
Data/       EventProviding protocol + two implementations, EventStore (@Observable),
            WeatherService, WikipediaService, LocationProvider, Secrets
Views/      Discover, Towns, TownDetail, Map, Saved, EventDetail + components
Theme/      Color and surface decisions in one place
```

Event sources sit behind a single protocol:

```
EventProviding
├── BundledEventProvider     always available, offline, no key
└── TicketmasterProvider     initializes to nil without a key, so the app degrades cleanly
```

`EventStore` merges both, deduplicates, and exposes the filtered and grouped
results the views read. Because it uses `@Observable`, SwiftUI tracks only the
properties each view actually touches — typing in the search field doesn't
redraw the map.

---

## Notable details

- **Photo fallbacks.** Wikipedia's lead image for small villages is often a
  county locator map rather than a photograph. The app detects these and
  substitutes a curated Wikimedia Commons photo — which is why White River
  Junction shows a streetscape instead of a shaded county outline.
- **Photo attribution.** Commons images are CC BY-SA, so the photographer and
  license are fetched alongside each image and displayed over it.
- **Graceful degradation.** No network, no key, or a rate-limited API each
  reduce what's shown without producing an error state or an empty screen.
- **Forecast honesty.** Open-Meteo forecasts run ~16 days out. Events beyond
  that omit the forecast row rather than showing a guess.

---

## Sample data

`Data/events.json` is clearly-labeled sample content written for this project.
Venues are real places in these towns; coordinates are approximate. It exists so
the app is fully functional the moment it's cloned, with no signup step.

---

## History

This started as a college capstone that read events from the Facebook Graph API.
That API was locked down years ago, so the original fetch returned nothing. The
rewrite replaced it with sources that are actually open, and moved the app from
Core Data and `ObservableObject` to SwiftData and `@Observable`.

> **Note on the old version:** the original committed a Facebook access token
> directly in source. It has been removed, but it remains in git history at
> commit `077ae4f`. Any such token should be treated as compromised and revoked.

---

## Credits

- Weather data by [Open-Meteo.com](https://open-meteo.com), CC BY 4.0
- Town photos and summaries from [Wikipedia](https://en.wikipedia.org) and
  [Wikimedia Commons](https://commons.wikimedia.org), CC BY-SA
- Event data from [Ticketmaster](https://developer.ticketmaster.com) when configured
