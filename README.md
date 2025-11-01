# Takt - Image to Calendar Event Extractor

Takt is a SwiftUI-based iOS app that automatically extracts event information from images and creates calendar events. The app uses iOS's built-in Vision framework for text recognition and provides a comprehensive calendar management system.

## Features

### 🖼️ Image Processing
- **Multiple Input Sources**: Import images from photo library, camera, or paste from clipboard
- **OCR Text Recognition**: Uses Vision framework for accurate text extraction
- **Smart Parsing**: Automatically identifies event names, dates, and deadlines from extracted text

### 📅 Calendar Management
- **Monthly Calendar View**: Interactive calendar with event indicators
- **Event Details**: Comprehensive event information including notes and deadlines
- **Event Management**: Add, edit, delete, and mark events as completed
- **Search & Filter**: Find events by name or notes with search functionality

### 💾 Offline Functionality
- **Local Storage**: All events are stored locally using UserDefaults
- **No Internet Required**: Works completely offline
- **Data Persistence**: Events are automatically saved and restored

### 🎯 Smart Event Extraction
- **Date Recognition**: Supports multiple date formats (MM/DD/YYYY, DD/MM/YYYY, MMM DD, etc.)
- **Time Support**: Handles both date-only and date-time formats
- **Deadline Detection**: Automatically identifies and sets deadlines
- **Event Naming**: Intelligently extracts event names from text content

## Technical Architecture

### Core Components

1. **Models**
   - `Event`: Data model for calendar events with properties for name, date, deadline, notes, and completion status

2. **Services**
   - `TextRecognitionService`: Handles OCR using Vision framework and parses extracted text
   - `EventStorageService`: Manages local data persistence and provides event filtering/searching

3. **Views**
   - `ContentView`: Main tab-based interface
   - `ImagePickerView`: Image selection and processing interface
   - `CalendarView`: Monthly calendar with event display
   - `EventsListView`: List view with search and management capabilities
   - `EventDetailView`: Detailed event information and actions
   - `EditEventView`: Event editing interface
   - `AddEventView`: Manual event creation

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Vision Framework**: iOS text recognition and analysis
- **PhotosUI**: Modern photo picker integration
- **UserDefaults**: Local data persistence
- **iOS 18.0+**: Latest iOS features and APIs

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
- **Cloud Sync**: iCloud integration for cross-device synchronization
- **Reminders**: Push notifications for upcoming events and deadlines
- **Export Options**: Share events via email, messages, or calendar apps
- **Advanced OCR**: Better text parsing for complex document layouts
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
