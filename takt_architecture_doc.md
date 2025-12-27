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
- **Vision**: Text recognition from images
- **EventKit**: (Future) Apple Reminders integration
- **Foundation**: Date parsing, networking
- **NaturalLanguage**: Multi-stage text parsing (Stage 2)

---

## 🧠 Intelligent Parsing Roadmap

### Architecture: Multi-Stage Detection Pipeline

The app uses a progressive enhancement approach for event extraction:

```
┌────────────────────────────────────────────────────────────────┐
│                   TextEventParser Service                       │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Stage 1: Regex Patterns (CURRENT)                       │  │
│  │  ✅ Fast, deterministic date matching                    │  │
│  │  ✅ Patterns: dd.MM.yyyy, MM/dd/yyyy, yyyy-MM-dd         │  │
│  │  ✅ Deadline keywords: "bis zum", "deadline", "MHD"      │  │
│  │  Performance: <10ms, offline, no ML overhead            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Stage 2: Natural Language Framework (PLANNED)           │  │
│  │  🔄 NSDataDetector for natural dates                     │  │
│  │     - "Wed 31 Aug" → Date object                         │  │
│  │     - "next Friday" → calculated date                    │  │
│  │  🔄 NLTagger for entity recognition                      │  │
│  │     - Organizations: "Electric Ballroom"                 │  │
│  │     - Locations: venue detection                         │  │
│  │  🔄 Pattern matching for:                                │  │
│  │     - Times: "7pm" → notes field                         │  │
│  │     - Prices: "£17.00" → notes field                     │  │
│  │  Performance: ~50-100ms, still offline                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             ↓                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Stage 3: Apple Intelligence API (FUTURE - iOS 18.2+)    │  │
│  │  🔮 Semantic understanding of event context              │  │
│  │  🔮 Category detection:                                  │  │
│  │     - Concert, Meeting, Deadline, Expiration             │  │
│  │  🔮 Smart field extraction:                              │  │
│  │     - Artist names: "DEERHOOF +SACRED PAWS"              │  │
│  │     - Venue: "Electric Ballroom"                         │  │
│  │     - Ticket info: "£17.00 upsettherhythm.co.uk"         │  │
│  │  Performance: Variable, remains offline-capable          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Configuration: detectionStage = .regexOnly (switchable)       │
└────────────────────────────────────────────────────────────────┘
```

### Example Use Case: Concert Poster

**Input Text**:
```
DEERHOOF +SACRED PAWS
Wed 31 Aug
Electric Ballroom
7pm
£17.00
upsettherhythm.co.uk
```

**Stage 1 Output** (Current):
- No match (no dd.MM.yyyy pattern)
- Fallback: No event detected

**Stage 2 Output** (Planned):
- Date: "Wed 31 Aug" → August 31, 2025 (current year assumed)
- Name: "DEERHOOF +SACRED PAWS"
- Notes: "Electric Ballroom, 7pm, £17.00"
- Entities detected: Organization (DEERHOOF), Location (Electric Ballroom)

**Stage 3 Output** (Future):
- Date: August 31, 2025
- Name: "DEERHOOF + SACRED PAWS Concert"
- Category: 🎸 Concert
- Venue: "Electric Ballroom"
- Time: 19:00
- Price: £17.00
- Artist: "DEERHOOF"
- Supporting: "SACRED PAWS"
- Website: upsettherhythm.co.uk

### Implementation Status

| Stage | Status | Performance | Accuracy | Use Case |
|-------|--------|-------------|----------|----------|
| Regex | ✅ Implemented | <10ms | 95% for simple dates | "Return by 25.12.2024" |
| Natural Language | 🔄 Stub Added | ~50-100ms | 85% for natural dates | "Meeting next Friday" |
| Apple Intelligence | 🔮 Stub Added | Variable | 95%+ semantic | Complex posters |

### Configuration

```swift
// In TextEventParser.swift
private enum DetectionStage {
    case regexOnly           // Current: fast & simple
    case withNaturalLanguage // Stage 2: + NaturalLanguage
    case withAppleAI         // Stage 3: + Apple Intelligence
}

private let detectionStage: DetectionStage = .regexOnly
```

### Design Principles

1. **Offline-First**: All stages process on-device
2. **Progressive Enhancement**: Each stage adds capability without breaking previous stages
3. **Performance Tiers**: User can choose speed vs. accuracy
4. **Graceful Fallback**: If Stage 3 fails, fall back to Stage 2, then Stage 1
5. **iCloud for Backups Only**: No backend required for processing

### Future Work

- [ ] Implement NSDataDetector for natural dates (Stage 2)
- [ ] Add NLTagger for entity recognition (Stage 2)
- [ ] Research Apple Intelligence API availability (Stage 3)
- [ ] Add configuration UI for detection stage selection
- [ ] Performance benchmarking across stages
- [ ] A/B testing for accuracy improvements

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

**Version**: 1.1
**Last Updated**: December 27, 2024
**Maintainer**: Artem Alekseev
