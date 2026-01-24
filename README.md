# Takt - Image to Calendar Event Extractor

Takt is a SwiftUI-based iOS app that automatically extracts event information from images and creates calendar events. The app uses iOS's built-in Vision framework for text recognition and provides a comprehensive calendar management system.

## Features

### 🚀 Share Sheet Integration (Killer Feature)
- **Share from Anywhere**: Share photos directly from Photos app, Safari, or any app
- **Quick Capture**: Snap a poster/flyer → Share to Takt → Auto-extract event
- **Background Processing**: Events extracted automatically when shared
- **No App Switching**: Process images without leaving your current app

**Example Use Cases**:
- Concert poster on street → Photo → Share to Takt → Event added
- Email screenshot → Share to Takt → Meeting extracted
- Restaurant flyer → Share to Takt → Deadline saved
- Voice dictation on-the-go when you can't type

### 🖼️ Image Processing
- **Multiple Input Sources**: Import images from photo library, camera, or paste from clipboard
- **OCR Text Recognition**: Uses Vision framework for accurate text extraction
- **Smart Parsing**: Automatically identifies event names, dates, and deadlines from extracted text
- **Natural Language Detection**: Handles complex phrasing like "Wed 31 Aug Electric Ballroom 7pm"

### 📅 Calendar Management
- **Monthly Calendar View**: Interactive calendar with event indicators
- **Event Details**: Comprehensive event information including notes and deadlines
- **Event Management**: Add, edit, delete, and mark events as completed
- **Search & Filter**: Find events by name or notes with search functionality

### 💾 Offline Functionality
- **Local Storage**: All events are stored locally using UserDefaults
- **No Internet Required**: Works completely offline
- **Data Persistence**: Events are automatically saved and restored

### 🎯 Smart Event Extraction (Multi-Stage Detection)
- **Stage 1 - Regex Patterns**: Fast detection of simple dates (25.12.2024, 12/25/2024)
- **Stage 2 - Natural Language** (NSDataDetector): Natural dates ("Wed 31 Aug"), context-aware deadline detection
- **Stage 3 - Apple Intelligence** (Future): Semantic understanding, category detection (Concerts, Meetings)
- **Deadline Detection**: Automatically identifies and sets deadlines
- **Event Naming**: Intelligently extracts event names from text content
- **Offline-First**: All processing happens on-device, no backend required

## Technical Stack

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Vision Framework**: iOS text recognition and analysis
- **PhotosUI**: Modern photo picker integration
- **UserDefaults**: Local data persistence
- **iOS 18.0+**: Latest iOS features and APIs

### Architecture
- **MVVM + Clean Architecture**: Separation of concerns with clear layer boundaries
- **Protocol-Based DI**: Dependency injection for testability
- **@Observable Pattern**: Modern Swift observation (iOS 17+)
- **Async/Await**: Modern concurrency throughout

## Installation & Setup

### Prerequisites
- Xcode 15.0+
- iOS 18.0+ deployment target
- macOS 14.0+ for development

### Setup Steps
1. Clone the repository
2. Open `Takt.xcodeproj` in Xcode
3. Select your development team in project settings
4. Build and run on device or simulator

### Required Permissions
- **Camera**: For taking photos of documents
- **Photo Library**: For accessing saved images
- **Microphone**: For camera functionality (if needed)

## Usage Guide

### 1. Importing Images
1. Tap the "Import" tab
2. Choose image source (Photo Library, Camera, or Clipboard)
3. Select or capture an image containing event information

### 2. Extracting Events
1. After selecting an image, tap "Extract Event Details"
2. The app will process the image and extract text
3. Review the extracted text and parsed event information
4. Tap "Add to Calendar" to save the event

### 3. Managing Events
1. Use the "Calendar" tab to view events in monthly format
2. Tap on dates to see events for that day
3. Use the "Events" tab for a comprehensive list view
4. Search events using the search bar
5. Tap on events to view details or make changes

### 4. Creating Events Manually
1. Tap the "+" button in the Events tab
2. Fill in event details (name, date, deadline, notes)
3. Tap "Add Event" to save

## Supported Date Formats

The app recognizes various date formats:
- `MM/DD/YYYY` (e.g., 12/25/2024)
- `DD/MM/YYYY` (e.g., 25/12/2024)
- `MMM DD, YYYY` (e.g., Dec 25, 2024)
- `YYYY-MM-DD` (e.g., 2024-12-25)
- `MMM DD` (e.g., Dec 25)
- `MM/DD/YYYY h:mm a` (e.g., 12/25/2024 2:30 PM)
- Natural language: "13 Jan 2026", "Starting on 6 Apr 2026"
- German formats: "dd.MM.yyyy", "dd.MM.yy"

## Data Structure

### Event Model
```swift
struct Event: Identifiable, Codable {
    let id = UUID()
    var name: String
    var date: Date
    var deadline: Date?
    var notes: String?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}
```

## Future Enhancements

### Planned Features
- **Share Sheet Extension**: Receive images from Photos, Safari, and other apps (HIGH PRIORITY)
- **Apple Intelligence Integration**: Semantic understanding for complex event posters
- **Category Auto-Detection**: Concerts, Meetings, Deadlines, etc.
- **Cloud Sync**: iCloud integration for cross-device synchronization (backups only)
- **Reminders**: Push notifications for upcoming events and deadlines
- **Export Options**: Share events via email, messages, or calendar apps
- **Batch Processing**: Import multiple images at once
- **Event Templates**: Predefined event types and templates

### Technical Improvements
- **Core Data**: Replace UserDefaults with Core Data for better performance
- **Widgets**: iOS home screen widgets for quick event viewing
- **Siri Integration**: Voice commands for event management
- **Dark Mode**: Enhanced dark mode support
- **Accessibility**: Improved VoiceOver and accessibility features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests, please open an issue on GitHub.

---

**Note**: This app is designed to work offline and does not require internet connectivity. All data is stored locally on the device for privacy and offline functionality.
