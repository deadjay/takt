# Takt

Takt is an iOS app that extracts dates and deadlines from images and text. Point your camera at a concert ticket, food label, or subscription screenshot — Takt pulls out the dates and turns them into events.

Everything runs on-device. No cloud, no accounts, no tracking.

## How It Works

1. **Scan** — Take a photo, pick from your library, or paste text
2. **Review** — Takt extracts dates and suggests event titles you can tap to edit
3. **Save** — Events appear in your list, sorted around today

### What It Can Read

- Concert tickets and posters
- Food expiry labels (MHD, best before, zu verbrauchen bis)
- Subscription renewal screenshots
- Receipts with deadlines
- Any text with a date in it

### Supported Date Formats

- German: `25.12.2024`, `25.12.24`, `dd.MM.`
- US: `12/25/2024`, `MM/dd`
- ISO: `2024-12-25`
- Natural language: "Wed 31 Aug", "Starting on 13 Jan 2026"
- Deadline prefixes: "bis", "fällig", "deadline", "due", "best before"
- Times: `14:30`, `3pm`, `11 Uhr`

## Features

- **OCR** — Vision framework text recognition from camera or photos
- **Two-stage parsing** — Regex patterns for structured dates, NSDataDetector for natural language
- **Events list** — Chronological list with a Today divider and auto-scroll
- **Calendar view** — Monthly overview with event indicators
- **Search** — Filter events by name or notes
- **Source image preview** — Tap to see the original scan
- **Deadline tracking** — "4 Days Left", "Today", "Overdue" labels
- **Dark/Light/System mode** — Toggle in Settings
- **Fully offline** — All data stored locally on device

## Tech Stack

- SwiftUI (iOS 18.0+)
- Vision framework (OCR)
- NSDataDetector + regex (date parsing)
- MVVM + Clean Architecture
- UserDefaults persistence
- No third-party dependencies

## Building

Requires Xcode 16+ and iOS 18.0+ deployment target.

```
git clone <repo-url>
open Takt.xcodeproj
```

Select your development team, build and run.

## Project Structure

```
Takt/
  Modules/
    Scan/           — Camera, photo picker, text input
    EventsList/     — Chronological event list with search
    Settings/       — Appearance mode toggle
  Views/
    CalendarView    — Monthly calendar
    EventDetailView — Event detail sheet
    Components/     — Confirmation card, image preview
  Domain/
    Entities/       — Event, AppSettings
    UseCases/       — Business logic protocols + implementations
  Data/
    Repositories/   — UserDefaults persistence
  Services/
    TextEventParserService  — Two-stage date extraction
    TextRecognitionService  — Vision OCR wrapper
  Infrastructure/
    DIContainer     — Dependency injection
```

## License

MIT
