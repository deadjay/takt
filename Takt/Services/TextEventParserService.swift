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

    private let detectionStage: DetectionStage = .regexOnly // Currently using Stage 1

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
                let dateKey = "\(dateInfo.date.timeIntervalSince1970)"
                guard !processedDates.contains(dateKey) else { continue }
                
                processedDates.insert(dateKey)
                
                // Extract event name
                let eventName = extractEventName(from: trimmedLine, dateInfo: dateInfo)
                
                // Look for additional context
                let notes = extractNotes(from: lines, currentIndex: index)
                
                // Determine dates
                let (eventDate, deadline) = determineEventAndDeadline(dateInfo: dateInfo)
                
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
        formatter.dateFormat = format
        
        if let date = formatter.date(from: text) {
            return date
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
        
        return nil
    }
    
    private func extractEventName(from text: String, dateInfo: DateInfo) -> String {
        var nameText = text.replacingOccurrences(of: dateInfo.matchedText, with: "")
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
    
    private func determineEventAndDeadline(dateInfo: DateInfo) -> (eventDate: Date, deadline: Date?) {
        if dateInfo.isDeadline {
            let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dateInfo.date) ?? dateInfo.date
            return (reminderDate, dateInfo.date)
        }
        return (dateInfo.date, nil)
    }
    
    // MARK: - Stage 2: Natural Language Enhancement (Stub)

    /// Enhance events using Natural Language framework
    /// TODO: Implement entity recognition (venues, prices, categories)
    /// TODO: Detect natural language dates ("Wed 31 Aug", "next Friday")
    /// Example use case: "DEERHOOF +SACRED PAWS Wed 31 Aug Electric Ballroom 7pm £17.00"
    private func enhanceWithNaturalLanguage(_ events: [Event], text: String) -> [Event] {
        // Stub for Stage 2 implementation
        // Will use:
        // - NSDataDetector for natural date detection
        // - NLTagger for entity recognition (places, organizations)
        // - Pattern matching for prices, times, categories
        return events
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

    // MARK: - Date Patterns

    private let datePatterns: [DatePattern] = [
        // German with deadline keywords
        DatePattern(regex: #"bis\s+(?:zum\s+)?(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"fällig\s+(?:am\s+)?(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"(?:return|rücksendung)\s+(?:by|bis)\s+(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"(?:pay|zahlen)\s+(?:until|bis)\s+(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),

        // Food expiry (must come before standard formats to match MHD: prefix)
        DatePattern(regex: #"(?:MHD|mhd):?\s*(\d{1,2})\.(\d{1,2})\.(\d{2,4})"#, format: "dd.MM.yy", isDeadline: true),

        // Standard German formats
        DatePattern(regex: #"\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b"#, format: "dd.MM.yyyy", isDeadline: false),
        DatePattern(regex: #"\b(\d{1,2})\.(\d{1,2})\.(\d{2})\b"#, format: "dd.MM.yy", isDeadline: false),

        // English formats
        DatePattern(regex: #"deadline\s+(\d{1,2})/(\d{1,2})/(\d{4})"#, format: "MM/dd/yyyy", isDeadline: true),
        DatePattern(regex: #"\b(\d{1,2})/(\d{1,2})/(\d{4})\b"#, format: "MM/dd/yyyy", isDeadline: false),
        DatePattern(regex: #"\b(\d{4})-(\d{2})-(\d{2})\b"#, format: "yyyy-MM-dd", isDeadline: false),
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
