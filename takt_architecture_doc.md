# Takt - Architecture Documentation

## 📐 Architecture Pattern

**MVVM + Clean Architecture (SwiftUI-optimized)**

This architecture provides:
- Clear separation of concerns
- Testability at every layer
- SwiftUI-native reactive patterns
- Scalability for future features

---

## 🏗️ Layer Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌────────────────┐              ┌──────────────────────┐   │
│  │     Views      │◄────────────►│     ViewModels       │   │
│  │   (SwiftUI)    │              │   (@Observable)      │   │
│  └────────────────┘              └──────────┬───────────┘   │
└──────────────────────────────────────────────┼──────────────┘
                                               │
┌──────────────────────────────────────────────┼──────────────┐
│                     DOMAIN LAYER             │              │
│  ┌─────────────────┐          ┌──────────────▼──────────┐   │
│  │     Models      │          │       Use Cases         │   │
│  │   (Entities)    │          │   (Business Logic)      │   │
│  └─────────────────┘          └──────────────┬──────────┘   │
│                                               │              │
│  ┌───────────────────────────────────────────▼──────────┐   │
│  │           Repository Protocols                       │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────┼──────────────┘
                                               │
┌──────────────────────────────────────────────┼──────────────┐
│                      DATA LAYER              │              │
│  ┌──────────────────────────────────────────▼──────────┐   │
│  │           Repository Implementations                │   │
│  └──────────────────────────┬──────────────────────────┘   │
│                             │                              │
│  ┌──────────────────────────▼──────────────────────────┐   │
│  │                  Services                           │   │
│  │  (TextRecognitionService, TextEventParser)          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Directory Structure

```
Takt/
├── TaktApp.swift                    # App entry point
│
├── Presentation/
│   ├── Modules/
│   │   ├── TextInput/
│   │   │   ├── TextInputView.swift         # UI
│   │   │   └── TextInputViewModel.swift    # State & logic
│   │   ├── Scanner/
│   │   │   ├── ScannerView.swift
│   │   │   └── ScannerViewModel.swift
│   │   └── EventsList/
│   │       ├── EventsListView.swift
│   │       └── EventsListViewModel.swift
│   │
│   └── Views/                       # Reusable components
│       ├── ImagePickerView.swift
│       ├── TextInputPickerView.swift
│       ├── CalendarView.swift
│       └── AddEventView.swift
│
├── Domain/                          # Business Logic
│   ├── Entities/
│   │   └── Event.swift              # Core domain model
│   │
│   ├── UseCases/
│   │   ├── AddEventUseCase.swift
│   │   ├── DeleteEventUseCase.swift
│   │   ├── GetEventsUseCase.swift
│   │   └── UpdateEventUseCase.swift
│   │
│   └── Repositories/                # Protocol definitions
│       └── EventRepositoryProtocol.swift
│
├── Data/                            # Infrastructure
│   ├── Repositories/
│   │   └── UserDefaultsEventRepository.swift
│   │
│   └── Services/
│       ├── TextRecognitionServiceProtocol.swift
│       ├── TextEventParser.swift              # Unified parser
│       └── EventStorageService.swift
│
├── Infrastructure/
│   └── DIContainer.swift            # Dependency injection
│
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

---

## 🎯 Layer Responsibilities

### 1. Presentation Layer
- **Views** (SwiftUI): Pure UI, no business logic
- **ViewModels** (`@Observable`): State management, coordinates Use Cases

### 2. Domain Layer
- **Entities**: Core models (Event)
- **Use Cases**: Business logic (single responsibility)
- **Repository Protocols**: Data access contracts

### 3. Data Layer
- **Repositories**: Implement domain protocols
- **Services**: External integrations (Vision, EventKit, parsers)

### 4. Infrastructure Layer
- **DIContainer**: Dependency injection, object lifecycle

---

## 🔄 Data Flow

### Example: User Pastes Text to Create Event

```
1. TextInputView (user pastes text)
        ↓
2. TextInputViewModel.processText()
        ↓
3. TextEventParser.parseEvents(text)
        ↓
4. ViewModel.extractedEvents = [...]
        ↓
5. View re-renders (shows extracted events)
        ↓
6. User confirms → AddEventUseCase.execute(event)
        ↓
7. EventRepository.save(event)
        ↓
8. Persisted to UserDefaults/CoreData
```

---

## 🧪 Testing Strategy

### ViewModel Tests:
```swift
@Test("Processes text and extracts events")
func testProcessText() async {
    let viewModel = TextInputViewModel(...)
    viewModel.inputText = "Return by 25.12.2024"
    
    await viewModel.processText()
    
    #expect(viewModel.extractedEvents.count == 1)
}
```

### Use Case Tests:
```swift
@Test("AddEventUseCase saves event")
func testAddEvent() async throws {
    let mockRepo = MockEventRepository()
    let useCase = DefaultAddEventUseCase(repository: mockRepo)
    
    try await useCase.execute(event)
    
    #expect(mockRepo.savedEvents.count == 1)
}
```

---

## 🔧 Dependency Injection

```swift
class DIContainer {
    // Services (Singletons)
    lazy var textParser = TextEventParser()
    
    // Repositories
    lazy var eventRepository: EventRepositoryProtocol = 
        UserDefaultsEventRepository()
    
    // Use Cases (Factory)
    func makeAddEventUseCase() -> AddEventUseCaseProtocol {
        DefaultAddEventUseCase(repository: eventRepository)
    }
    
    // ViewModels (Factory)
    func makeTextInputViewModel() -> TextInputViewModel {
        TextInputViewModel(
            textRecognitionService: textRecognitionService,
            addEventUseCase: makeAddEventUseCase()
        )
    }
}
```

---

## 📝 Naming Conventions

- **Views**: `[Feature]View.swift` (e.g., `TextInputView.swift`)
- **ViewModels**: `[Feature]ViewModel.swift`
- **Use Cases**: `[Action]UseCase.swift`
- **Protocols**: `[Name]Protocol.swift`
- **Implementations**: `Default[Name]` prefix

---

## 🚀 Adding New Features

1. **Define Entity** (if needed) in `Domain/Entities/`
2. **Create Use Case** protocol + implementation
3. **Create/Update Repository** (if data access needed)
4. **Create ViewModel** in `Presentation/Modules/`
5. **Create View** in `Presentation/Modules/`
6. **Wire in DIContainer**
7. **Write Tests**

---

## ✅ Best Practices

### DO:
- Keep ViewModels framework-agnostic (no SwiftUI imports)
- Use dependency injection
- Write Use Cases for business logic
- Use `@Observable` for ViewModels (iOS 17+)
- Test ViewModels and Use Cases

### DON'T:
- Put business logic in Views
- Access repositories directly from ViewModels
- Create ViewModels inside Views (inject them)
- Use singletons except in DIContainer

---

## 🔄 Key Architectural Decisions

### Why MVVM + Clean?
- **MVVM**: Native fit for SwiftUI's reactive nature
- **Clean Architecture**: Domain logic independent of frameworks
- **Combined**: Best of both worlds - testable, scalable, SwiftUI-friendly

### Why Not VIPER?
- Too many layers for SwiftUI's reactive patterns
- Router/Wireframe awkward with NavigationStack
- MVVM provides sufficient structure with less boilerplate

### Why @Observable over ObservableObject?
- iOS 17+ native
- Less boilerplate
- Better performance
- Cleaner syntax

---

## 📚 Core Dependencies

- **SwiftUI**: UI framework
- **Vision/VisionKit**: Text recognition (OCR) from images
- **EventKit**: Apple Reminders/Calendar integration
- **Foundation**: Date parsing (NSDataDetector), networking
- **NaturalLanguage**: (Optional) Enhanced text parsing, language detection

---

## 🔬 Research Findings (Jan 7, 2026)

### Date Extraction & OCR Pipeline Research

**Research Goal**: Determine best iOS frameworks/libraries for extracting dates from images (food labels, subscriptions, tickets, bills) with multilingual support (German/English), offline/privacy-first.

#### Key Recommendations:
1. **OCR Layer**: Vision/VisionKit framework (handles multilingual, noisy text, fully offline)
2. **Date Parsing**: NSDataDetector for natural language + regex for specific formats (MHD, bis, fällig)
3. **Enhanced Parsing** (optional): SwiftDate or SoulverCore for complex multilingual date parsing
4. **Language Detection**: NSLinguisticTagger for keyword/language tagging
5. **Event Creation**: EventKit for calendar events and reminders

#### Architecture Pipeline:
```
1. Image Input → Vision OCR → Raw Text
2. Clean Noise + Detect Keywords/Language (NSLinguisticTagger)
3. Parse Dates (Regex for specific formats / NSDataDetector for natural language)
4. Structure into EKEvent/EKReminder
```

#### Parsing Approach Decision:
- **MVP**: Rule-based (regex + NSDataDetector) ✅
  - Pros: Fast, lightweight, 85%+ accuracy, fully offline
  - Cons: Manual regex maintenance, less flexible with edge cases
- **Future Enhancement**: On-device LLM/CoreML models
  - Pros: Better accuracy on unstructured/noisy inputs
  - Cons: Slower, larger binary size, overkill for MVP

#### Commercial App Inspirations:
- **Fantastical**: Natural language date parsing
- **Prizmo**: Robust OCR scanning
- **Text Scanner**: Excellent noisy text handling

#### MVP Priorities:
1. ✅ 85%+ accuracy on core use cases (food expiry, subscriptions, tickets, bills)
2. ✅ Fully offline/private (no cloud APIs)
3. ✅ Test with real images from target scenarios
4. Smart routing: Keyword detection → specialized parser

#### Current Implementation Status:
- ✅ NSDataDetector integration (enhanced Jan 11, 2026)
- ✅ Regex patterns for German/English deadline keywords
- ✅ Multiline/noisy text support
- ✅ 44/44 unit tests passing
- ✅ 6/7 real image OCR tests passing (86% success rate)
- ✅ Vision framework integration (complete)
- ✅ In-app event storage (UserDefaults)
- ⏳ EventKit export (post-MVP feature - optional iCal export)

---

## 🧪 TextEventParser Implementation (Jan 11, 2026)

### Two-Stage Parsing Pipeline

The `TextEventParserService` uses a sophisticated two-stage pipeline to extract dates from OCR text:

```
┌─────────────────────────────────────────────┐
│         TextEventParserService              │
├─────────────────────────────────────────────┤
│                                             │
│  Stage 1: Regex Parsing                     │
│  ├─ German formats (dd.MM.yyyy, dd.MM.yy)   │
│  ├─ English formats (MM/dd/yyyy)            │
│  ├─ Deadline keywords in regex              │
│  └─ Returns: [Event] array                  │
│                                             │
│  Stage 2: NSDataDetector Enhancement        │
│  ├─ Natural language dates                  │
│  ├─ Filter vague dates                      │
│  ├─ 200-char context window                 │
│  ├─ Day-based duplicate detection           │
│  ├─ Smart replacement logic                 │
│  └─ Returns: Enhanced [Event] array         │
│                                             │
│  Stage 3: Apple Intelligence (Future)       │
│  └─ Semantic understanding (iOS 18.2+)      │
│                                             │
└─────────────────────────────────────────────┘
```

### Stage 1: Regex-Based Extraction

**Purpose**: Fast, deterministic parsing of structured date formats

**Supported Formats**:
- German: `dd.MM.yyyy`, `dd.MM.yy`, `dd.MM.`
- English: `MM/dd/yyyy`, `yyyy-MM-dd`
- Deadline keywords: "bis", "fällig", "MHD", "verbrauchen"

**Limitations**:
- Cannot parse natural language dates ("13 Jan 2026")
- Single-line context only
- Misses deadline keywords on separate lines

### Stage 2: NSDataDetector Enhancement

**Purpose**: Capture natural language dates and improve context awareness

**Key Features**:

#### 1. Natural Language Date Parsing
```swift
guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
```
- Parses: "13 Jan 2026", "Starting on 6 Apr 2026", "6. Januar 2026"
- Handles both English and German natural language dates

#### 2. Vague Date Filtering
**Problem**: NSDataDetector picks up unhelpful dates
**Solution**: Filter out:
- Relative dates: "today", "tomorrow", "heute", "morgen"
- Day-of-week dates: "Montag 18.05.26", "Tuesday, 6 January 2026"
- Time-only matches: "19:00", "20:00"
- App message dates: "Starting today"

```swift
if lowercasedMatch == "today" ||
   lowercasedMatch == "tomorrow" ||
   lowercasedMatch.contains("dienstag") || // + all day names
   lowercasedMatch.range(of: "^\\d{1,2}:\\d{2}$", options: .regularExpression) != nil {
    continue // Skip this match
}
```

#### 3. 200-Character Context Window
**Problem**: Deadline keywords often on different line from date
**Example**:
```
verbrauchen bis:
30.12.25
```

**Solution**: Check 200 characters (100 before + 100 after) for deadline keywords
```swift
let startIndex = max(0, matchRange.location - 200)
let endIndex = min(nsText.length, matchRange.location + matchRange.length + 200)
let contextRange = NSRange(location: startIndex, length: endIndex - startIndex)
let contextText = nsText.substring(with: contextRange)

let isDeadline = contextText.lowercased().contains("verbrauchen") ||
                contextText.lowercased().contains("haltbar") ||
                contextText.lowercased().contains("mhd")
```

**Note**: "starting on" and "ab dem" are NOT deadline keywords (they indicate subscription start dates)

#### 4. Smart Duplicate Detection
**Problem**: Regex and NSDataDetector both find the same date, but with different context
**Example**:
- Regex: Finds "30.12.25" → event with day=30, no deadline
- NSDataDetector: Finds "30.12.25" WITH "verbrauchen" context → reminder on day=29, deadline on day=30

**Challenge**: Dates have different timestamps due to timezones
```
Regex event:     2025-12-29 23:00:00 +0000  (day 30 in local time)
NSDataDetector:  2025-12-30 11:00:00 +0000
Difference:      43200 seconds (12 hours)
```

**Solution**: Compare by calendar day instead of exact timestamp
```swift
let calendar = Calendar.current
let eventComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
let nsDataDetectorComponents = calendar.dateComponents([.year, .month, .day], from: date)

let isSameDay = eventComponents.year == nsDataDetectorComponents.year &&
               eventComponents.month == nsDataDetectorComponents.month &&
               eventComponents.day == nsDataDetectorComponents.day
```

#### 5. Context-Based Replacement
**Logic**: If NSDataDetector has better context (deadline detection), replace the regex event
```swift
if let duplicateIndex = duplicateIndex {
    let existingEvent = allEvents[duplicateIndex]

    if isDeadline && existingEvent.deadline == nil {
        // NSDataDetector found deadline context but regex didn't
        allEvents.remove(at: duplicateIndex)  // Replace!
    } else {
        continue  // Skip duplicate
    }
}
```

### Deadline Logic

When `isDeadline: true`, the parser creates a **reminder 1 day before** the actual deadline:

```swift
if dateInfo.isDeadline {
    let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dateWithTime) ?? dateWithTime
    return (reminderDate, dateWithTime)  // event.date = reminder, event.deadline = actual deadline
}
```

**Example**: Expiry date "30.12.25" with "verbrauchen bis:"
- `event.date` = Dec 29, 2025 (reminder date - shown in calendar)
- `event.deadline` = Dec 30, 2025 (actual deadline - stored for reference)

### Test Results (Real Image OCR)

| Test | Status | Date Format | Challenge |
|------|--------|-------------|-----------|
| Deerhoof concert | ✅ | `18.05.26` | German short format |
| Fabulous EN | ✅ | `Starting on 13 Jan 2026` | Natural language + filtering "today" |
| Fabulous DE | ✅ | `Ab dem 13.01.2026` | German natural language |
| one sec pro | ✅ | `Starting on 6 Apr 2026` | Natural language + filtering "Starting today" |
| Cheese | ✅ | `26.02.26` | German short format |
| **Chicken** | ✅ | `30.12.25` | **Multi-line deadline + timezone handling** |
| Eggs | ❌ | N/A | OCR too garbled (known limitation) |

**Success Rate**: 86% (6/7 tests)

### Code Locations

- **Parser Service**: `Takt/Services/TextEventParserService.swift`
- **Test File**: `TaktTests/RealImageOCRTests.swift`
- **Test Images**: `TaktTests/Resources/*.jpeg`
- **Detection Stage**: Line 27 - `private let detectionStage: DetectionStage = .withNaturalLanguage`
- **NSDataDetector Logic**: Lines 329-461 - `enhanceWithNaturalLanguage()` method

### Future Enhancements (Stage 3)

**Apple Intelligence Integration** (iOS 18.2+):
- Semantic understanding of event types
- Automatic category detection (Concert, Meeting, Deadline, Subscription, Food Expiry)
- Smart field extraction (artist names, venues, ticket info, subscription details)
- Improved handling of ambiguous or noisy OCR text

---

## 🎨 UI Patterns

### State Management:
```swift
// ViewModel
@Observable
final class TextInputViewModel {
    var inputText: String = ""
    var isLoading: Bool = false
    
    @MainActor
    func processText() async {
        // Business logic
    }
}

// View
struct TextInputView: View {
    @State private var viewModel: TextInputViewModel
    
    var body: some View {
        // UI automatically updates
    }
}
```

---

## 🔒 Architecture Rules

1. **Views** never import domain/data layers
2. **ViewModels** never import SwiftUI
3. **Domain** never imports UIKit/SwiftUI
4. **Data** can import iOS frameworks
5. **Dependencies flow inward** (Presentation → Domain ← Data)

---

**Version**: 1.2
**Last Updated**: January 11, 2026 - NSDataDetector Enhancement
**Maintainer**: Artem Alekseev
