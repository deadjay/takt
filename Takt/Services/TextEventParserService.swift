//
//  TextEventParser.swift
//  Takt
//
//  Created by Artem Alekseev on 16.11.25.
//

import Foundation
import NaturalLanguage

// MARK: - Text Event Parser
/// Unified parser for extracting events from text (used by both image scanner and text input)
/// Supports multiple detection stages:
/// - Stage 1: Regex patterns (fast, simple dates like "25.12.2024")
/// - Stage 2: Natural Language Framework (natural dates like "Wed 31 Aug", entity recognition)
/// - Stage 3: Apple Intelligence API (future, iOS 18.2+)
final class TextEventParser: TextEventParserServiceProtocol {

    // MARK: - Configuration

    private enum DetectionStage {
        case regexOnly           // Stage 1: Fast regex patterns only
        case withNaturalLanguage // Stage 2: + NaturalLanguage framework
        case withAppleAI         // Stage 3: + Apple Intelligence (future)
    }

    private let detectionStage: DetectionStage = .withNaturalLanguage // Stage 2: Regex + NSDataDetector
    private let dataDetector: NSDataDetector?

    // MARK: - Initialization

    init(dataDetector: NSDataDetector? = nil) {
        // Create data detector for natural language date parsing
        // If one isn't provided, create it lazily
        self.dataDetector = dataDetector ?? (try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue))
    }

    // MARK: - Public Interface

    /// Parse text and extract all events with dates
    func parseEvents(from text: String) -> [Event] {
        // Stage 1: Regex-based extraction (current implementation)
        var events = parseEventsWithRegex(from: text)

        // Stage 2: Natural Language enhancement (stub for future)
        if detectionStage == .withNaturalLanguage || detectionStage == .withAppleAI {
            events = enhanceWithNaturalLanguage(events, text: text)
        }

        // Stage 3: Apple Intelligence enhancement (stub for future)
        if detectionStage == .withAppleAI {
            events = enhanceWithAppleIntelligence(events, text: text)
        }

        return events
    }

    // MARK: - Stage 1: Regex Parsing

    private func parseEventsWithRegex(from text: String) -> [Event] {
        var events: [Event] = []
        let lines = text.components(separatedBy: .newlines)

        var processedDates: Set<String> = [] // Avoid duplicates

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            // Try to find dates in this line using regex
            if let dateInfo = extractDate(from: trimmedLine) {
                // Use day/month/year for deduplication (ignore time component)
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: dateInfo.date)
                let dateKey = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
                guard !processedDates.contains(dateKey) else { continue }

                processedDates.insert(dateKey)

                // Check previous line for food expiry keywords if date wasn't marked as deadline
                var updatedDateInfo = dateInfo
                if !dateInfo.isDeadline && index > 0 {
                    let previousLine = lines[index - 1].lowercased()
                    if previousLine.contains("haltbar") ||  // "Haltbar bis", "Mindestens haltbar bis"
                       previousLine.contains("zu verbrauchen") ||
                       previousLine.contains("best before") ||
                       previousLine.contains("use by") ||
                       previousLine.contains("mhd") ||
                       previousLine.range(of: "bis\\s*[:.]?\\s*$", options: .regularExpression) != nil {  // "bis:" or "bis." at end
                        updatedDateInfo = DateInfo(date: dateInfo.date, isDeadline: true, matchedText: dateInfo.matchedText)
                    }
                }

                // Extract time (if present)
                let timeInfo = extractTime(from: trimmedLine)

                // Extract event name
                let eventName = extractEventName(from: trimmedLine, dateInfo: updatedDateInfo, timeInfo: timeInfo)

                // Look for additional context
                let notes = extractNotes(from: lines, currentIndex: index)

                // Determine dates (with time if available)
                let (eventDate, deadline) = determineEventAndDeadline(dateInfo: updatedDateInfo, timeInfo: timeInfo)
                
                let event = Event(
                    name: eventName.isEmpty ? "Reminder" : eventName,
                    date: eventDate,
                    deadline: deadline,
                    notes: notes.isEmpty ? nil : notes
                )
                
                events.append(event)
            }
        }
        
        return events
    }
    
    // MARK: - Private Methods
    
    private func extractDate(from text: String) -> DateInfo? {
        for pattern in datePatterns {
            if let dateInfo = tryPattern(pattern, in: text) {
                return dateInfo
            }
        }
        return nil
    }
    
    private func tryPattern(_ pattern: DatePattern, in text: String) -> DateInfo? {
        guard let regex = try? NSRegularExpression(pattern: pattern.regex, options: [.caseInsensitive]) else {
            return nil
        }

        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) else {
            return nil
        }

        // Extract the full matched text
        let matchedText = nsText.substring(with: match.range)

        // Extract date components from capture groups or use the full match
        var dateText = matchedText

        // If we have capture groups (range count > 1), extract just the date part
        if match.numberOfRanges > 1 {
            var components: [String] = []
            for i in 1..<match.numberOfRanges {
                let range = match.range(at: i)
                if range.location != NSNotFound {
                    components.append(nsText.substring(with: range))
                }
            }

            // Reconstruct date based on format
            if pattern.format.contains(".") {
                dateText = components.joined(separator: ".")
            } else if pattern.format.contains("/") {
                dateText = components.joined(separator: "/")
            } else if pattern.format.contains("-") {
                dateText = components.joined(separator: "-")
            }
        } else {
            // No capture groups, clean up the matched text
            dateText = extractDateNumbers(from: matchedText)
        }

        guard let date = parseDate(dateText, format: pattern.format) else {
            return nil
        }

        return DateInfo(date: date, isDeadline: pattern.isDeadline, matchedText: matchedText)
    }
    
    private func extractDateNumbers(from text: String) -> String {
        let keywords = ["bis", "zum", "fällig", "deadline", "due", "return", "rücksendung",
                       "pay", "zahlen", "MHD", "mhd", "best before", "until", "by", "am", "on", ":"]
        
        var result = text
        for keyword in keywords {
            result = result.replacingOccurrences(
                of: "\\b\(keyword)\\b",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseDate(_ text: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        let currentYear = Calendar.current.component(.year, from: Date())

        // Handle dates without year FIRST - default to current year
        // Do NOT try to parse these formats directly as DateFormatter defaults to year 2000

        // German format without year (e.g., "02.12." -> "02.12.2025")
        if format == "dd.MM." {
            let components = text.components(separatedBy: ".")
            if components.count >= 2 {
                let fullDateText = "\(components[0]).\(components[1]).\(currentYear)"
                formatter.dateFormat = "dd.MM.yyyy"
                return formatter.date(from: fullDateText)
            }
        }

        // English format without year (e.g., "12/25" -> "12/25/2025")
        if format == "MM/dd" {
            let components = text.components(separatedBy: "/")
            if components.count >= 2 {
                let fullDateText = "\(components[0])/\(components[1])/\(currentYear)"
                formatter.dateFormat = "MM/dd/yyyy"
                return formatter.date(from: fullDateText)
            }
        }

        // ISO format without year (e.g., "12-25" -> "2025-12-25")
        if format == "MM-dd" {
            let components = text.components(separatedBy: "-")
            if components.count >= 2 {
                let fullDateText = "\(currentYear)-\(components[0])-\(components[1])"
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: fullDateText)
            }
        }

        // Handle 2-digit years (e.g., "25.12.24" -> "25.12.2024")
        if format.contains("yy") && !format.contains("yyyy") {
            let components = text.components(separatedBy: CharacterSet(charactersIn: "./- "))
            if components.count >= 3, let year = Int(components[2]), year < 100 {
                let fullYear = 2000 + year
                let fullDateText = "\(components[0]).\(components[1]).\(fullYear)"
                formatter.dateFormat = format.replacingOccurrences(of: "yy", with: "yyyy")
                return formatter.date(from: fullDateText)
            }
        }

        // Try standard parsing for formats with full year
        formatter.dateFormat = format
        if let date = formatter.date(from: text) {
            return date
        }

        return nil
    }

    private func extractTime(from text: String) -> TimeInfo? {
        for pattern in timePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern.regex, options: [.caseInsensitive]) else {
                continue
            }

            let nsText = text as NSString
            guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) else {
                continue
            }

            // Extract the full matched text
            let matchedText = nsText.substring(with: match.range)

            // Extract hour
            guard match.numberOfRanges > pattern.hourGroup else { continue }
            let hourRange = match.range(at: pattern.hourGroup)
            guard hourRange.location != NSNotFound else { continue }
            let hourString = nsText.substring(with: hourRange)
            guard var hour = Int(hourString) else { continue }

            // Extract minute (if pattern has it)
            var minute = 0
            if let minuteGroup = pattern.minuteGroup, match.numberOfRanges > minuteGroup {
                let minuteRange = match.range(at: minuteGroup)
                if minuteRange.location != NSNotFound {
                    let minuteString = nsText.substring(with: minuteRange)
                    minute = Int(minuteString) ?? 0
                }
            }

            // Handle AM/PM for English formats
            if matchedText.lowercased().contains("pm") && hour < 12 {
                hour += 12
            } else if matchedText.lowercased().contains("am") && hour == 12 {
                hour = 0
            }

            // Validate time
            guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else { continue }

            return TimeInfo(hour: hour, minute: minute, matchedText: matchedText)
        }

        return nil
    }

    private func extractEventName(from text: String, dateInfo: DateInfo, timeInfo: TimeInfo?) -> String {
        var nameText = text.replacingOccurrences(of: dateInfo.matchedText, with: "")

        // Remove time string if present
        if let timeInfo = timeInfo {
            nameText = nameText.replacingOccurrences(of: timeInfo.matchedText, with: "")
        }

        nameText = nameText.trimmingCharacters(in: CharacterSet(charactersIn: ":-,;.!?"))
        nameText = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if nameText.isEmpty || nameText.count < 3 {
            return ""
        }
        
        return nameText.prefix(1).uppercased() + nameText.dropFirst()
    }
    
    private func extractNotes(from lines: [String], currentIndex: Int) -> String {
        var notes: [String] = []
        let checkRange = max(0, currentIndex - 1)...min(lines.count - 1, currentIndex + 1)
        
        for i in checkRange where i != currentIndex {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if extractDate(from: line) == nil && line.count >= 5 {
                notes.append(line)
            }
        }
        
        return notes.joined(separator: " ")
    }
    
    private func determineEventAndDeadline(dateInfo: DateInfo, timeInfo: TimeInfo?) -> (eventDate: Date, deadline: Date?) {
        // Apply time to the date if available
        let dateWithTime = applyTime(to: dateInfo.date, timeInfo: timeInfo)

        if dateInfo.isDeadline {
            let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dateWithTime) ?? dateWithTime
            return (reminderDate, dateWithTime)
        }
        return (dateWithTime, nil)
    }

    private func applyTime(to date: Date, timeInfo: TimeInfo?) -> Date {
        guard let timeInfo = timeInfo else { return date }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = timeInfo.hour
        components.minute = timeInfo.minute
        components.second = 0

        return calendar.date(from: components) ?? date
    }
    
    // MARK: - Stage 2: Natural Language Enhancement

    /// Enhance events using Natural Language framework
    /// Uses NSDataDetector for natural language dates ("13 Jan 2026", "6 Apr 2026", etc.)
    private func enhanceWithNaturalLanguage(_ events: [Event], text: String) -> [Event] {
        var allEvents = events

        // Use injected NSDataDetector to find dates that regex didn't catch
        guard let detector = dataDetector else {
            return allEvents
        }

        let nsText = text as NSString
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            guard let date = match.date else { continue }

            // Check if this date was already found by regex
            // If so, we might want to REPLACE it if NSDataDetector has better context
            var duplicateIndex: Int? = nil

            let calendar = Calendar.current
            let nsDataDetectorComponents = calendar.dateComponents([.year, .month, .day], from: date)

            for (index, event) in allEvents.enumerated() {
                // Compare dates by day/month/year, not by exact timestamp
                // This handles timezone differences and different time components
                let eventComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
                let isSameDay = eventComponents.year == nsDataDetectorComponents.year &&
                               eventComponents.month == nsDataDetectorComponents.month &&
                               eventComponents.day == nsDataDetectorComponents.day

                if isSameDay {
                    duplicateIndex = index
                    break
                }

                // Or if regex found this as a deadline
                if let deadline = event.deadline {
                    let deadlineComponents = calendar.dateComponents([.year, .month, .day], from: deadline)
                    let isSameDeadlineDay = deadlineComponents.year == nsDataDetectorComponents.year &&
                                           deadlineComponents.month == nsDataDetectorComponents.month &&
                                           deadlineComponents.day == nsDataDetectorComponents.day
                    if isSameDeadlineDay {
                        duplicateIndex = index
                        break
                    }
                }
            }

            // Extract the matched text and surrounding context
            let matchRange = match.range
            let matchedText = nsText.substring(with: matchRange)

            // Skip vague relative dates, app message dates, and time-only matches
            let lowercasedMatch = matchedText.lowercased()
            if lowercasedMatch == "today" ||
               lowercasedMatch == "tomorrow" ||
               lowercasedMatch == "heute" ||
               lowercasedMatch == "morgen" ||
               lowercasedMatch.contains("starting today") ||
               lowercasedMatch.contains("ab heute") ||
               lowercasedMatch.range(of: "^\\d{1,2}:\\d{2}$", options: .regularExpression) != nil ||
               (lowercasedMatch.contains("dienstag") || lowercasedMatch.contains("tuesday") ||
                lowercasedMatch.contains("montag") || lowercasedMatch.contains("monday") ||
                lowercasedMatch.contains("mittwoch") || lowercasedMatch.contains("wednesday") ||
                lowercasedMatch.contains("donnerstag") || lowercasedMatch.contains("thursday") ||
                lowercasedMatch.contains("freitag") || lowercasedMatch.contains("friday") ||
                lowercasedMatch.contains("samstag") || lowercasedMatch.contains("saturday") ||
                lowercasedMatch.contains("sonntag") || lowercasedMatch.contains("sunday")) {
                continue
            }

            // Check surrounding context (200 chars) for deadline keywords
            let startIndex = max(0, matchRange.location - 200)
            let endIndex = min(nsText.length, matchRange.location + matchRange.length + 200)
            let contextRange = NSRange(location: startIndex, length: endIndex - startIndex)
            let contextText = nsText.substring(with: contextRange)

            // NOTE: "starting on" and "ab dem" are NOT deadlines (new subscription starting)
            // BUT "renewal date" IS a deadline - user needs advance warning to cancel
            let lowercasedContext = contextText.lowercased()
            let isDeadline = lowercasedContext.contains("renewal date") ||
                            lowercasedContext.contains("renewal") ||
                            lowercasedContext.contains("renews") ||
                            lowercasedContext.contains("deadline") ||
                            lowercasedContext.contains("due") ||
                            lowercasedContext.contains("verbrauchen") ||
                            lowercasedContext.contains("haltbar") ||
                            lowercasedContext.contains("mhd")

            // If we found a duplicate from regex, decide whether to replace or skip
            if let dupIndex = duplicateIndex {
                let existingEvent = allEvents[dupIndex]

                // If NSDataDetector found deadline context but regex didn't, replace the regex event
                if isDeadline && existingEvent.deadline == nil {
                    // Remove the regex event and continue to add the NSDataDetector event
                    allEvents.remove(at: dupIndex)
                } else {
                    // Otherwise skip this duplicate
                    continue
                }
            }

            // Extract time from the full text (not just this line)
            // This handles cases where time is on a different line (e.g., "20 Juni 2026\nSa. 16:00")
            let timeInfo = extractTime(from: contextText)

            // If no time found, default to 09:00 instead of noon
            let dateWithTime: Date
            if let timeInfo = timeInfo {
                dateWithTime = applyTime(to: date, timeInfo: timeInfo)
            } else {
                // Default to 09:00 for events without explicit time
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = 9
                components.minute = 0
                components.second = 0
                dateWithTime = calendar.date(from: components) ?? date
            }

            // Get the line containing this date for event name extraction
            let lineRange = nsText.lineRange(for: matchRange)
            let lineText = nsText.substring(with: lineRange)

            // Extract event name from nearby lines (not just the date line)
            var eventName = lineText.replacingOccurrences(of: matchedText, with: "")
            eventName = eventName.trimmingCharacters(in: CharacterSet(charactersIn: ":-,;.!?"))
            eventName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)

            // If the date line doesn't have a good name, look at surrounding lines
            if eventName.isEmpty || eventName.count < 3 {
                // Get all lines and find the first substantial one that isn't a date/time
                let lines = text.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Skip if line contains the matched date or is too short
                    if trimmed.contains(matchedText) || trimmed.count < 3 {
                        continue
                    }
                    // Skip if line looks like a time
                    if extractTime(from: trimmed) != nil {
                        continue
                    }
                    // Skip if line contains another date
                    if extractDate(from: trimmed) != nil {
                        continue
                    }
                    // This line looks like a good event name
                    eventName = trimmed
                    break
                }
            }

            if eventName.isEmpty {
                eventName = "Reminder"
            }

            // Create event using the date with applied time
            let (eventDate, deadline) = determineEventAndDeadline(
                dateInfo: DateInfo(date: dateWithTime, isDeadline: isDeadline, matchedText: matchedText),
                timeInfo: nil  // Already applied time to date above
            )

            let event = Event(
                name: eventName,
                date: eventDate,
                deadline: deadline,
                notes: nil
            )

            allEvents.append(event)
        }

        return allEvents
    }

    // MARK: - Stage 3: Apple Intelligence Enhancement (Stub)

    /// Enhance events using Apple Intelligence API (iOS 18.2+)
    /// TODO: Integrate with Apple Intelligence for semantic understanding
    /// TODO: Category detection (Concert, Meeting, Deadline, etc.)
    /// TODO: Smart field extraction (artist names, venues, ticket info)
    private func enhanceWithAppleIntelligence(_ events: [Event], text: String) -> [Event] {
        // Stub for Stage 3 implementation
        // Will use Apple Intelligence API when available
        // Remains offline-first with fallback to Stage 1 & 2
        return events
    }

    // MARK: - Time Patterns

    private let timePatterns: [TimePattern] = [
        // German formats with "Uhr"
        TimePattern(regex: #"(\d{1,2}):(\d{2})\s*Uhr"#, hourGroup: 1, minuteGroup: 2),  // "14:30 Uhr"
        TimePattern(regex: #"(\d{1,2})\.(\d{2})\s*Uhr"#, hourGroup: 1, minuteGroup: 2),  // "14.30 Uhr"
        TimePattern(regex: #"(\d{1,2})\s*Uhr"#, hourGroup: 1, minuteGroup: nil),         // "11 Uhr"

        // English formats with AM/PM
        TimePattern(regex: #"(\d{1,2}):(\d{2})\s*([ap]m)"#, hourGroup: 1, minuteGroup: 2),  // "3:30pm", "3:30 PM"
        TimePattern(regex: #"(\d{1,2})\s*([ap]m)"#, hourGroup: 1, minuteGroup: nil),        // "3pm", "3 PM"

        // 24-hour format (ISO-style)
        TimePattern(regex: #"\b(\d{2}):(\d{2})\b"#, hourGroup: 1, minuteGroup: 2),  // "14:30", "09:00"
    ]

    // MARK: - Date Patterns

    private let datePatterns: [DatePattern] = [
        // German with deadline keywords (with year - must come before no-year patterns)
        DatePattern(regex: #"bis\s+(?:zum\s+)?(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"fällig\s+(?:am\s+)?(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"(?:return|rücksendung)\s+(?:by|bis)\s+(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"(?:pay|zahlen)\s+(?:until|bis)\s+(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),

        // Food expiry (must come before standard formats to match MHD: prefix)
        DatePattern(regex: #"(?:MHD|mhd):?\s*(\d{1,2})\.(\d{1,2})\.(\d{2,4})"#, format: "dd.MM.yy", isDeadline: true),

        // Food expiry with full German text (multiline, so date might be on next line)
        DatePattern(regex: #"(?:MINDESTENS\s+HALTBAR\s+BIS|mindestens\s+haltbar\s+bis)[:\s]*(\d{1,2})\.(\d{1,2})\.(\d{2,4})"#, format: "dd.MM.yy", isDeadline: true),
        DatePattern(regex: #"(?:MINDESTENS\s+HALTBAR\s+BIS|mindestens\s+haltbar\s+bis)[:\s]*(\d{1,2})\.(\d{1,2})\."#, format: "dd.MM.", isDeadline: true),
        DatePattern(regex: #"(?:ZU\s+VERBRAUCHEN\s+BIS|zu\s+verbrauchen\s+bis)[:\s]*(\d{1,2})\.(\d{1,2})\.(\d{2,4})"#, format: "dd.MM.yy", isDeadline: true),
        DatePattern(regex: #"(?:ZU\s+VERBRAUCHEN\s+BIS|zu\s+verbrauchen\s+bis)[:\s]*(\d{1,2})\.(\d{1,2})\."#, format: "dd.MM.", isDeadline: true),

        // German with deadline keywords (no year - defaults to current year)
        DatePattern(regex: #"bis\s+(?:zum\s+)?(\d{1,2})\.(\d{1,2})\."#, format: "dd.MM.", isDeadline: true),
        DatePattern(regex: #"fällig\s+(?:am\s+)?(\d{1,2})\.(\d{1,2})\."#, format: "dd.MM.", isDeadline: true),

        // Standard German formats (with year)
        DatePattern(regex: #"\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b"#, format: "dd.MM.yyyy", isDeadline: false),
        DatePattern(regex: #"\b(\d{1,2})\.(\d{1,2})\.(\d{2})\b"#, format: "dd.MM.yy", isDeadline: false),

        // English formats (with year)
        DatePattern(regex: #"deadline\s+(\d{1,2})/(\d{1,2})/(\d{4})"#, format: "MM/dd/yyyy", isDeadline: true),
        DatePattern(regex: #"\b(\d{1,2})/(\d{1,2})/(\d{4})\b"#, format: "MM/dd/yyyy", isDeadline: false),
        DatePattern(regex: #"\b(\d{4})-(\d{2})-(\d{2})\b"#, format: "yyyy-MM-dd", isDeadline: false),

        // English formats (no year - defaults to current year)
        DatePattern(regex: #"deadline\s+(\d{1,2})/(\d{1,2})\b"#, format: "MM/dd", isDeadline: true),
        DatePattern(regex: #"\b(\d{1,2})/(\d{1,2})\b"#, format: "MM/dd", isDeadline: false),

        // German format without year (must be LAST - catches standalone dates like "23.01" or "23.01.")
        // Will be marked as deadline if previous line contains food expiry keywords
        DatePattern(regex: #"\b(\d{1,2})\.(\d{1,2})\.?"#, format: "dd.MM.", isDeadline: false),
    ]
}

// MARK: - Supporting Types

private struct DatePattern {
    let regex: String
    let format: String
    let isDeadline: Bool
}

private struct DateInfo {
    let date: Date
    let isDeadline: Bool
    let matchedText: String
}

private struct TimeInfo {
    let hour: Int
    let minute: Int
    let matchedText: String
}

private struct TimePattern {
    let regex: String
    let hourGroup: Int    // Which capture group contains the hour
    let minuteGroup: Int? // Which capture group contains the minute (nil if no minutes)
}
