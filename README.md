# VT2NH

An iOS event-discovery app for Vermont and New Hampshire. Browse what's happening
across 31 towns in both states, filter by category, see it on a map, check the forecast for the
day of the event, and save what you want to go to.

Built with SwiftUI, SwiftData, MapKit, and EventKit. Every data source is free
and requires no paid plan.

**[→ System architecture](ARCHITECTURE.md)** — layer diagrams, the two-source
loading model, image-resolution cascade, and the degradation matrix.

---

## What it does

- **Browse ~200 events across 31 towns** in Vermont and New Hampshire, grouped
  into Today / Tomorrow / This Week / Later
- **Filter** by eight categories or free-only, and search names, venues, and towns
- **Pick a state, then a town** — each with a photo, Wikipedia summary, and link
- **See everything on a map**, pins tinted by category
- **Check the forecast** for the event's date at the venue's coordinates
- **Save events** and **add them to your calendar**

## Screens

| Discover | Browse | Map | Saved |
|---|---|---|---|
| Search and filter events, grouped into Today / Tomorrow / This Week / Later | Pick a state, then a town — each with a photo, Wikipedia summary, and article link | Every event as a category-tinted pin across both states | Bookmarked events, split into upcoming and past |

---

## Data sources

All free. No paid tier, no credit card.

| Source | What it provides | Key required | Limits |
|---|---|---|---|
| **Bundled feed** (`Data/events.json`) | 108 sample events across 31 towns | No | None — works offline |
| **Public iCalendar feeds** | ~90 *real* events from 7 library and museum calendars | **No** | None — open format, not an API |
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

## Tests

```bash
xcodebuild test -project FBEventsMockProject.xcodeproj \
  -scheme FBEventsMockProject \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

43 tests across 8 suites, covering the logic most likely to lose data silently:
the deduplication identity, town/state matching (the two Manchesters), time
bucketing, event labelling, the iCalendar parser's edge cases (folded lines,
escaped text, three date encodings), and the bundled feed's integrity — every
event maps to a catalog town, every town has events, no date resolves to the
past, and deduplication discards nothing.

---

## Architecture

Full write-up with diagrams: **[ARCHITECTURE.md](ARCHITECTURE.md)**

```
FBEventsMockProject/
├── Models/
│   ├── Event.swift             Event, Venue, EventCategory, TimeBucket
│   ├── AppLocation.swift       USState, AppLocation, LocationCatalog (31 towns)
│   └── SavedEvent.swift        SwiftData @Model
├── Data/
│   ├── EventProviding.swift    The source protocol
│   ├── BundledEventProvider    events.json — offline, no key
│   ├── TicketmasterProvider    Live events — optional, free key
│   ├── CalendarFeedProvider    Real events from public .ics feeds — keyless
│   ├── ICSParser.swift         iCalendar (RFC 5545) reader
│   ├── EventStore.swift        @Observable state: merge, filter, group
│   ├── WeatherService.swift    Open-Meteo, keyless
│   ├── WikipediaService.swift  Town photos, summaries, Commons credit
│   ├── VenueImagery.swift      Hand-verified venue photographs
│   ├── LocationProvider.swift  One-shot CoreLocation for "near me"
│   ├── Secrets.swift           Reads the gitignored Secrets.plist
│   └── events.json             108 sample events across 31 towns
├── Views/
│   ├── RootView.swift          TabView shell
│   ├── DiscoverView.swift      Search, filters, time-bucketed sections
│   ├── TownsView.swift         State chooser → town grid
│   ├── TownDetailView.swift    Hero photo, Wikipedia, that town's events
│   ├── EventMapScreen.swift    Category-tinted pins
│   ├── EventDetailView.swift   Forecast, calendar, directions, save
│   ├── SavedEventsView.swift   @Query-backed, upcoming vs past
│   └── Components/             EventCard, FilterBar, photo banners
└── Theme/Theme.swift           Color, type, and surface decisions
```

Event sources sit behind a single protocol:

```
EventProviding
├── BundledEventProvider     always available, offline, no key
├── CalendarFeedProvider     real events from public .ics feeds, keyless
└── TicketmasterProvider     initializes to nil without a key, so the app degrades cleanly
```

`EventStore` merges all three, deduplicates, and exposes the filtered and grouped
results the views read. Because it uses `@Observable`, SwiftUI tracks only the
properties each view actually touches — typing in the search field doesn't
redraw the map.

---

## Notable details

- **Town names are not unique.** Manchester is a town in *both* states, so
  matching events to a town by name alone silently mixed the two. Matching
  requires the state to agree.
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
- **Calendar feeds are read, not scraped.** iCalendar is an open format served
  over plain HTTP; a published `.ics` exists to be subscribed to. Feeds are
  fetched concurrently and failures are dropped rather than thrown, so one
  library being unreachable cannot empty the screen.

---

## Sample data

`Data/events.json` is clearly-labeled sample content written for this project:
108 events across all 31 towns. Venues are real places in those towns and venue
coordinates are approximate, offset from each town's Wikipedia centroid. It
exists so the app is fully functional the moment it's cloned, with no signup step.

---

## History

This started as a college capstone that read events from the Facebook Graph API.
That API was locked down years ago, so the original fetch returned nothing. The
rewrite replaced it with sources that are actually open, and moved the app from
Core Data and `ObservableObject` to SwiftData and `@Observable`.

> **Note on the old version:** the original committed a Facebook access token
> directly in source. It has been removed from the code *and* purged from every
> commit in history, so it no longer appears anywhere in this repository.
> Verified against the provider: the token was a 60-day page token that expired
> on 1 June 2025, so it was already inert. Keys now load from a gitignored
> `Secrets.plist`, and a missing key disables one optional feature rather than
> breaking the app.

---

## Not done yet

Tracked honestly rather than omitted:

- **No test target.** The pure logic is the place to start — date bucketing,
  dedupe, town matching, and the feed's offset resolution are all testable
  without a simulator.
- **No privacy manifest.** `PrivacyInfo.xcprivacy` is required for App Store
  submission.
- **App icon** is the original capstone artwork.
- **iPad and accessibility** have not had a dedicated pass. Dynamic Type is
  respected via semantic fonts but has not been audited at the largest sizes.

---

## What's next

Honest list of what this does not have yet.

- **Most event data is still a bundled sample feed.** Six of 31 towns pull
  real events from public calendars; the rest use written sample content with
  real venues. Coverage is limited by what venues actually publish: of ~60
  library, museum, theatre, college and municipal sites probed, seven have a
  working `.ics`.
- **Accessibility not fully audited.** Dynamic Type and VoiceOver need a real
  pass; a few serif display sizes are fixed point values.
- **iPad layout untested.** The grid adapts, but nothing has been verified there.
- **No CI.** Tests exist and pass locally, but nothing runs them automatically
  on push.

---

## Credits

- Weather data by [Open-Meteo.com](https://open-meteo.com), CC BY 4.0
- Town photos and summaries from [Wikipedia](https://en.wikipedia.org) and
  [Wikimedia Commons](https://commons.wikimedia.org), CC BY-SA
- Event data from [Ticketmaster](https://developer.ticketmaster.com) when configured
