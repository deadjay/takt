//
//  TextEventParser.swift
//  Takt
//
//  Created by Artem Alekseev on 16.11.25.
//

import Foundation

// MARK: - Text Event Parser
/// Unified parser for extracting events from text (used by both image scanner and text input)
final class TextEventParser: TextEventParserServiceProtocol {
    
    // MARK: - Public Interface
    
    /// Parse text and extract all events with dates
    func parseEvents(from text: String) -> [Event] {
        var events: [Event] = []
        let lines = text.components(separatedBy: .newlines)
        
        var processedDates: Set<String> = [] // Avoid duplicates
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            // Try to find dates in this line
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
        guard let match = text.range(of: pattern.regex, options: [.regularExpression, .caseInsensitive]) else {
            return nil
        }
        
        let matchedText = String(text[match])
        let dateText = extractDateNumbers(from: matchedText)
        
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
    
    // MARK: - Date Patterns
    
    private let datePatterns: [DatePattern] = [
        // German with deadline keywords
        DatePattern(regex: #"bis\s+(?:zum\s+)?(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"fällig\s+(?:am\s+)?(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"(?:return|rücksendung)\s+(?:by|bis)\s+(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        DatePattern(regex: #"(?:pay|zahlen)\s+(?:until|bis)\s+(\d{1,2})\.(\d{1,2})\.(\d{4})"#, format: "dd.MM.yyyy", isDeadline: true),
        
        // Standard German formats
        DatePattern(regex: #"\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b"#, format: "dd.MM.yyyy", isDeadline: false),
        DatePattern(regex: #"\b(\d{1,2})\.(\d{1,2})\.(\d{2})\b"#, format: "dd.MM.yy", isDeadline: false),
        
        // Food expiry
        DatePattern(regex: #"(?:MHD|mhd):?\s*(\d{1,2})\.(\d{1,2})\.(\d{2,4})"#, format: "dd.MM.yy", isDeadline: true),
        
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
