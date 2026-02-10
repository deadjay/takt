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

                // Check previous lines (up to 3 lines back) for food expiry keywords if date wasn't marked as deadline
                var updatedDateInfo = dateInfo
                if !dateInfo.isDeadline && index > 0 {
                    // Check up to 3 previous lines for deadline keywords
                    let linesToCheck = max(0, index - 3)..<index
                    var foundDeadlineKeyword = false

                    for i in linesToCheck {
                        let lineToCheck = lines[i].lowercased()
                        if lineToCheck.contains("haltbar") ||  // "Haltbar bis", "Mindestens haltbar bis"
                           lineToCheck.contains("zu verbrauchen") ||
                           lineToCheck.contains("best before") ||
                           lineToCheck.contains("use by") ||
                           lineToCheck.contains("mhd") ||
                           lineToCheck.range(of: "bis\\s*[:.]?\\s*$", options: .regularExpression) != nil {  // "bis:" or "bis." at end
                            foundDeadlineKeyword = true
                            break
                        }
                    }

                    if foundDeadlineKeyword {
                        updatedDateInfo = DateInfo(date: dateInfo.date, isDeadline: true, matchedText: dateInfo.matchedText)
                    }
                }

                // Extract time (if present)
                let timeInfo = extractTime(from: trimmedLine)

                // Extract event name (look at surrounding lines too)
                let eventName = extractEventName(from: lines, currentIndex: index, dateInfo: updatedDateInfo, timeInfo: timeInfo)

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

        // German format without year (e.g., "02.12." -> "02.12.2026")
        // Simple rule: Always use current year
        // TODO: Flag dates in the past for user warning dialog
        if format == "dd.MM." {
            let components = text.components(separatedBy: ".")
            if components.count >= 2 {
                let fullDateText = "\(components[0]).\(components[1]).\(currentYear)"
                formatter.dateFormat = "dd.MM.yyyy"
                return formatter.date(from: fullDateText)
            }
        }

        // English format without year (e.g., "12/25" -> "12/25/2026")
        // Simple rule: Always use current year
        // TODO: Flag dates in the past for user warning dialog
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

        // Handle 2-digit years (e.g., "25.12.24" -> "25.12.2024" or "02/09/26" -> "02/09/2026")
        if format.contains("yy") && !format.contains("yyyy") {
            let separator = format.contains("/") ? "/" : (format.contains("-") ? "-" : ".")
            let components = text.components(separatedBy: CharacterSet(charactersIn: "./- "))
            if components.count >= 3, let year = Int(components[2]), year < 100 {
                let fullYear = 2000 + year
                let fullDateText = "\(components[0])\(separator)\(components[1])\(separator)\(fullYear)"
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

    private func extractEventName(from lines: [String], currentIndex: Int, dateInfo: DateInfo, timeInfo: TimeInfo?) -> String {
        let dateLine = lines[currentIndex]

        // First, extract name from the date line itself (strip date + time)
        var dateLineName = dateLine.replacingOccurrences(of: dateInfo.matchedText, with: "")
        if let timeInfo = timeInfo {
            dateLineName = dateLineName.replacingOccurrences(of: timeInfo.matchedText, with: "")
        }
        dateLineName = cleanNameText(dateLineName)

        // Collect valid surrounding lines (up to 3 lines before, 2 after)
        var contextLines: [(index: Int, text: String)] = []

        let searchStart = max(0, currentIndex - 3)
        let searchEnd = min(lines.count - 1, currentIndex + 2)

        for i in searchStart...searchEnd {
            if i == currentIndex { continue }

            let trimmed = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty/short lines
            if trimmed.count < 3 { continue }
            // Skip lines that contain dates
            if extractDate(from: trimmed) != nil { continue }
            // Skip lines that are just times
            if extractTime(from: trimmed) != nil && trimmed.range(of: #"^\d{1,2}[.:]\d{2}\s*(Uhr|uhr|[ap]m)?$"#, options: .regularExpression) != nil { continue }
            // Skip label-style metadata (e.g., "Datum:", "Preis:")
            if trimmed.lowercased().range(of: #"^[a-zäöü]+:\s*$"#, options: .regularExpression) != nil { continue }
            // Skip lines that look like prices, weights, codes
            if trimmed.range(of: #"^[\d.,€$£%]+\s*(€|kg|g|ml|l)?$"#, options: .regularExpression) != nil { continue }
            // Skip batch/lot codes (e.g., "L04", "PN DE-1201")
            if trimmed.range(of: #"^[A-Z]{1,2}[\s-]?\d{2,}"#, options: .regularExpression) != nil && trimmed.count < 15 { continue }

            contextLines.append((index: i, text: trimmed))
        }

        // If date line has a good name already, use it (possibly enriched with one context line)
        if dateLineName.count >= 3 {
            // Add one preceding context line if it looks like a title
            if let preceding = contextLines.first(where: { $0.index < currentIndex }) {
                let combined = preceding.text + " - " + dateLineName
                if combined.count <= 80 {
                    return combined
                }
            }
            return dateLineName
        }

        // Date line had no name — use surrounding lines
        // Prefer lines before the date (titles are usually above)
        let beforeLines = contextLines.filter { $0.index < currentIndex }
        let afterLines = contextLines.filter { $0.index > currentIndex }

        var selectedLines = Array(beforeLines.prefix(2)) + Array(afterLines.prefix(1))
        selectedLines.sort { $0.index < $1.index }

        let result = selectedLines.map { $0.text }.joined(separator: "\n")

        if result.isEmpty || result.count < 3 {
            return ""
        }

        return result
    }

    /// Clean up extracted name text by removing weekday abbreviations and trimming
    private func cleanNameText(_ text: String) -> String {
        var nameText = text

        // Remove weekday abbreviations (e.g., "Sa.", "Mo.", "Sun.", etc.)
        let weekdayAbbreviations = ["mo.", "di.", "mi.", "do.", "fr.", "sa.", "so.",
                                   "mon.", "tue.", "wed.", "thu.", "fri.", "sat.", "sun."]
        for abbr in weekdayAbbreviations {
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: abbr)
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                nameText = regex.stringByReplacingMatches(in: nameText, range: NSRange(nameText.startIndex..., in: nameText), withTemplate: "")
            }
        }

        nameText = nameText.trimmingCharacters(in: CharacterSet(charactersIn: ":-,;.!?•"))
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

        // Normalize text for NSDataDetector:
        // 1. Replace newlines with spaces (helps parse "May\n18" -> "May 18")
        // 2. Capitalize month names so NSDataDetector recognizes "26 may" -> "26 May"
        let monthNames = ["january", "february", "march", "april", "may", "june",
                          "july", "august", "september", "october", "november", "december",
                          "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
        var normalizedText = text.replacingOccurrences(of: "\n", with: " ")
        for month in monthNames {
            // Replace lowercase/mixed-case month names with capitalized versions
            if let regex = try? NSRegularExpression(pattern: "\\b\(month)\\b", options: .caseInsensitive) {
                let capitalized = month.prefix(1).uppercased() + month.dropFirst()
                normalizedText = regex.stringByReplacingMatches(
                    in: normalizedText,
                    range: NSRange(normalizedText.startIndex..., in: normalizedText),
                    withTemplate: capitalized
                )
            }
        }

        let nsText = normalizedText as NSString
        let matches = detector.matches(in: normalizedText, options: [], range: NSRange(location: 0, length: nsText.length))

        // First pass: identify time-only matches and full date matches
        var hasFullDateMatch = false
        var timeOnlyMatches: Set<Int> = []

        for (index, match) in matches.enumerated() {
            guard let date = match.date else { continue }
            let matchRange = match.range
            let matchedText = nsText.substring(with: matchRange)

            // Check if this is a time-only match (e.g., "20:00", "20:00 Uhr", "3pm")
            let isTimeOnly = matchedText.range(of: #"^\d{1,2}:\d{2}(\s*(Uhr|uhr|pm|am|PM|AM))?$"#, options: .regularExpression) != nil

            if isTimeOnly {
                timeOnlyMatches.insert(index)
            } else {
                // Check if this has month/day information (not just time)
                let calendar = Calendar.current
                let components = calendar.dateComponents([.month, .day], from: date)
                if components.month != nil && components.day != nil {
                    // This is a real date (has month and day info)
                    let containsExplicitYear = matchedText.range(of: #"\b(19|20)\d{2}\b"#, options: .regularExpression) != nil ||
                                              matchedText.range(of: #"\d{1,2}[./]\d{1,2}[./]\d{2}\b"#, options: .regularExpression) != nil

                    // Also check if the matched text contains month names or date separators
                    let hasDateContent = matchedText.range(of: #"\d{1,2}[./]\d{1,2}"#, options: .regularExpression) != nil ||
                                        matchedText.range(of: #"jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|januar|februar|märz|april|mai|juni|juli|august|september|oktober|november|dezember"#, options: [.regularExpression, .caseInsensitive]) != nil

                    if hasDateContent || containsExplicitYear {
                        hasFullDateMatch = true
                    }
                }
            }
        }

        // Structure to hold match info with priority scoring
        struct MatchCandidate {
            let match: NSTextCheckingResult
            var date: Date
            let matchedText: String
            let contextText: String
            let isDeadline: Bool
            var priority: Int  // Higher = better
        }

        var candidates: [MatchCandidate] = []

        for (index, match) in matches.enumerated() {
            // Skip time-only matches if we found any full date matches
            if hasFullDateMatch && timeOnlyMatches.contains(index) {
                let matchRange = match.range
                let matchedText = nsText.substring(with: matchRange)
                print("DEBUG: Skipping time-only match '\(matchedText)' because full dates were found")
                continue
            }
            guard var date = match.date else { continue }

            let calendar = Calendar.current
            let matchRange = match.range
            let matchedText = nsText.substring(with: matchRange)

            // DEBUG: Print what NSDataDetector found
            print("NSDataDetector found: '\(matchedText)' -> date: \(date)")

            // Only adjust year if the matched text doesn't contain a year
            // Check for 4-digit years OR 2-digit years in date formats (dd.MM.yy, MM/dd/yy)
            let containsExplicitYear = matchedText.range(of: #"\b(19|20)\d{2}\b"#, options: .regularExpression) != nil ||
                                      matchedText.range(of: #"\d{1,2}[./]\d{1,2}[./]\d{2}\b"#, options: .regularExpression) != nil

            if !containsExplicitYear {
                // Date has no explicit year - always use current year
                // Simple rule: Don't auto-bump years
                // TODO: Flag dates in the past for user warning dialog
                let currentYear = calendar.component(.year, from: Date())
                var components = calendar.dateComponents([.month, .day, .hour, .minute], from: date)
                components.year = currentYear

                if let dateWithCurrentYear = calendar.date(from: components) {
                    print("DEBUG: Date '\(matchedText)' has no year - using current year \(currentYear)")
                    date = dateWithCurrentYear
                }
            }

            print("DEBUG: After year adjustment: '\(matchedText)' -> \(date)")

            // Check if this date was already found by regex
            // If so, we might want to REPLACE it if NSDataDetector has better context
            var duplicateIndex: Int? = nil

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

            // Skip vague relative dates, app message dates, time-only matches, and weekday-only dates
            let lowercasedMatch = matchedText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            // Check if the match is ONLY a weekday (with optional time)
            // Use simple string operations instead of complex regex
            let weekdays = ["mon", "montag", "monday", "tue", "dienstag", "tuesday",
                          "wed", "mittwoch", "wednesday", "thu", "donnerstag", "thursday",
                          "fri", "freitag", "friday", "sat", "samstag", "saturday",
                          "sun", "sonntag", "sunday"]

            var isWeekdayOnly = false
            for weekday in weekdays {
                // Check if match is ONLY a weekday (e.g., "mon" or "monday")
                if lowercasedMatch == weekday {
                    isWeekdayOnly = true
                    break
                }
                // Or weekday + time (e.g., "mon 20:00")
                if lowercasedMatch.hasPrefix(weekday + " ") {
                    // Remove weekday, check if remainder is only a time pattern
                    let remainder = String(lowercasedMatch.dropFirst(weekday.count + 1))
                    if remainder.range(of: #"^\d{1,2}:\d{2}$"#, options: .regularExpression) != nil {
                        isWeekdayOnly = true
                        break
                    }
                }
            }

            if lowercasedMatch == "today" ||
               lowercasedMatch == "tomorrow" ||
               lowercasedMatch == "heute" ||
               lowercasedMatch == "morgen" ||
               lowercasedMatch.contains("starting today") ||
               lowercasedMatch.contains("ab heute") ||
               lowercasedMatch.range(of: "^\\d{1,2}:\\d{2}$", options: .regularExpression) != nil ||
               isWeekdayOnly {
                print("DEBUG: Skipping vague date: '\(matchedText)'")
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

            // Calculate priority score for this match
            // Higher priority = more likely to be the relevant date
            var priority = 0

            // Subscription context keywords (high priority)
            if lowercasedContext.contains("starting on") || lowercasedContext.contains("ab dem") {
                priority += 10
            }
            if lowercasedContext.contains("subscription") || lowercasedContext.contains("renews") {
                priority += 5
            }

            // Deadline context (medium priority)
            if isDeadline {
                priority += 3
            }

            // Penalize weekday-prefixed dates (lower priority)
            // e.g., "Dienstag, 6. Januar" is less relevant than "Starting on 13 Jan"
            let weekdayPrefixes = ["montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag",
                                 "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            for weekdayPrefix in weekdayPrefixes {
                if lowercasedMatch.hasPrefix(weekdayPrefix) {
                    priority -= 5
                    break
                }
            }

            // Store candidate with priority
            candidates.append(MatchCandidate(
                match: match,
                date: date,
                matchedText: matchedText,
                contextText: contextText,
                isDeadline: isDeadline,
                priority: priority
            ))
        }

        // Sort candidates by priority (highest first), then process them
        candidates.sort { $0.priority > $1.priority }

        // Track which dates we've already added to avoid duplicates
        var processedDateKeys: Set<String> = []

        for candidate in candidates {
            var date = candidate.date
            let matchedText = candidate.matchedText
            let contextText = candidate.contextText
            let isDeadline = candidate.isDeadline
            let matchRange = candidate.match.range
            let calendar = Calendar.current

            // Check if this date was already found by regex
            // If so, skip it - regex patterns are more specific and should take precedence
            let nsDataDetectorComponents = calendar.dateComponents([.year, .month, .day], from: date)
            var duplicateIndex: Int? = nil

            print("DEBUG: Checking NSDataDetector date '\(matchedText)' (y:\(nsDataDetectorComponents.year ?? 0) m:\(nsDataDetectorComponents.month ?? 0) d:\(nsDataDetectorComponents.day ?? 0)) against \(allEvents.count) existing events")

            for (index, event) in allEvents.enumerated() {
                // Compare dates by day/month/year, not by exact timestamp
                let eventComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
                print("  Event \(index): date=\(event.date) (y:\(eventComponents.year ?? 0) m:\(eventComponents.month ?? 0) d:\(eventComponents.day ?? 0)), deadline=\(event.deadline?.description ?? "nil")")

                let isSameDay = eventComponents.year == nsDataDetectorComponents.year &&
                               eventComponents.month == nsDataDetectorComponents.month &&
                               eventComponents.day == nsDataDetectorComponents.day

                if isSameDay {
                    print("  ✓ Found duplicate: NSDataDetector date matches event[\(index)].date")
                    duplicateIndex = index
                    break
                }

                // Or if regex found this as a deadline
                if let deadline = event.deadline {
                    let deadlineComponents = calendar.dateComponents([.year, .month, .day], from: deadline)
                    print("  Checking deadline: y:\(deadlineComponents.year ?? 0) m:\(deadlineComponents.month ?? 0) d:\(deadlineComponents.day ?? 0)")
                    let isSameDeadlineDay = deadlineComponents.year == nsDataDetectorComponents.year &&
                                           deadlineComponents.month == nsDataDetectorComponents.month &&
                                           deadlineComponents.day == nsDataDetectorComponents.day
                    if isSameDeadlineDay {
                        print("  ✓ Found duplicate: NSDataDetector date matches event[\(index)].deadline")
                        duplicateIndex = index
                        break
                    }
                }
            }

            // If we found a duplicate from regex, skip it
            if duplicateIndex != nil {
                print("DEBUG: Skipping NSDataDetector date '\(matchedText)' - already found by regex")
                continue
            } else {
                print("DEBUG: No duplicate found - will add NSDataDetector date '\(matchedText)'")
            }

            // Check if we've already processed this date (from a higher-priority match)
            let dateKey = "\(nsDataDetectorComponents.year ?? 0)-\(nsDataDetectorComponents.month ?? 0)-\(nsDataDetectorComponents.day ?? 0)"
            if processedDateKeys.contains(dateKey) {
                print("DEBUG: Skipping lower-priority duplicate date: '\(matchedText)'")
                continue
            }
            processedDateKeys.insert(dateKey)

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

            // Extract event name from lines (use original text with newlines, not normalized)
            // Strategy: Capture up to 3 valid lines near the date
            // This gives user context (venue + title) to edit in confirmation UI
            let lines = text.components(separatedBy: .newlines)

            // Find which line contains the date
            var dateLineIndex = -1
            for (index, line) in lines.enumerated() {
                if line.contains(matchedText) {
                    dateLineIndex = index
                    break
                }
            }

            // Collect valid lines with their distance from date
            var validLines: [(index: Int, distance: Int, line: String)] = []

            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

                // Skip if too short or contains the date
                if trimmed.count < 3 || trimmed.contains(matchedText) {
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
                // Skip label-style metadata lines (e.g., "Datum:", "Uhrzeit:")
                let lowerTrimmed = trimmed.lowercased()
                if lowerTrimmed.range(of: #"^[a-zäöü]+:\s*"#, options: .regularExpression) != nil {
                    continue
                }

                // Calculate distance from date line
                let distance = dateLineIndex >= 0 ? abs(index - dateLineIndex) : 999
                validLines.append((index, distance, trimmed))
            }

            // Sort by distance (closest first), take up to 3 lines, restore original order
            validLines.sort(by: { $0.distance < $1.distance })
            let selectedLines = validLines.prefix(3).sorted(by: { $0.index < $1.index }).map { $0.line }

            // Join with newlines to preserve multi-line context
            var eventName = selectedLines.joined(separator: "\n")

            if eventName.isEmpty {
                eventName = "Reminder"
            }

            // Create event using the date with applied time
            let (eventDate, deadline) = determineEventAndDeadline(
                dateInfo: DateInfo(date: dateWithTime, isDeadline: isDeadline, matchedText: matchedText),
                timeInfo: nil  // Already applied time to date above
            )

            print("DEBUG: NSDataDetector creating event with name: '\(eventName)'")

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
        DatePattern(regex: #"(?:deadline|due)\s+(?:date\s+)?(\d{1,2})/(\d{1,2})/(\d{4})"#, format: "MM/dd/yyyy", isDeadline: true),

        // US format with 4-digit year (MM/dd/yyyy) - for dates like "12/25/2024"
        // Must check if day/month are valid for US format (month 1-12, day 1-31)
        DatePattern(regex: #"\b(\d{1,2})/(\d{1,2})/(\d{4})\b"#, format: "MM/dd/yyyy", isDeadline: false),

        // European slash format with 2-digit year (dd/MM/yy) - must come before MM/dd to prioritize European format
        DatePattern(regex: #"\b(\d{1,2})/(\d{1,2})/(\d{2})\b"#, format: "dd/MM/yy", isDeadline: false),
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
