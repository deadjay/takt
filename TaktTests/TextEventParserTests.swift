//
//  TextEventParserTests.swift
//  TaktTests
//
//  Created by Artem Alekseev on 27.12.25.
//

import Testing
import Foundation
@testable import Takt

@Suite("Text Event Parser Tests", .serialized)
struct TextEventParserTests {

    let parser = TextEventParser()

    // MARK: - German Date Format Tests

    @Test("Parse simple German date format dd.MM.yyyy")
    func testSimpleGermanDateFormat() throws {
        let text = "Return by 25.12.2024"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        // Event date should be the deadline date itself
        #expect(components.day == 25)
        #expect(components.month == 12)
        #expect(components.year == 2024)

        // Should have deadline set to the same date
        #expect(event.deadline != nil)

        if let deadline = event.deadline {
            let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(deadlineComponents.day == 25)
            #expect(deadlineComponents.month == 12)
            #expect(deadlineComponents.year == 2024)
        }
    }

    @Test("Parse German date without keyword")
    func testGermanDateWithoutKeyword() throws {
        let text = "Meeting on 31.01.2025"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 31)
        #expect(components.month == 1)
        #expect(components.year == 2025)

        // No deadline for non-deadline dates
        #expect(event.deadline == nil)
    }

    @Test("Parse German short year format dd.MM.yy")
    func testGermanShortYearFormat() throws {
        let text = "Expires 15.06.25"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 15)
        #expect(components.month == 6)
        #expect(components.year == 2025)
    }

    // MARK: - English Date Format Tests

    @Test("Parse English date format MM/dd/yyyy")
    func testEnglishDateFormat() throws {
        let text = "Due date 12/25/2024"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        // Event date should be the deadline date itself
        #expect(components.day == 25)
        #expect(components.month == 12)
        #expect(components.year == 2024)

        // Deadline should match the event date
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(deadlineComponents.day == 25)
            #expect(deadlineComponents.month == 12)
            #expect(deadlineComponents.year == 2024)
        }
    }

    @Test("Parse ISO date format yyyy-MM-dd")
    func testISODateFormat() throws {
        let text = "Event scheduled for 2025-03-15"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 15)
        #expect(components.month == 3)
        #expect(components.year == 2025)
    }

    // MARK: - Deadline Keyword Tests

    @Test("Parse German deadline with 'bis zum' keyword")
    func testGermanDeadlineBisZum() throws {
        let text = "Zahlung bis zum 30.06.2025"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)

        // Should have deadline
        #expect(event.deadline != nil)

        if let deadline = event.deadline {
            let calendar = Calendar.current
            let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(deadlineComponents.day == 30)
            #expect(deadlineComponents.month == 6)
            #expect(deadlineComponents.year == 2025)
        }
    }

    @Test("Parse German deadline with 'fällig' keyword")
    func testGermanDeadlineFaellig() throws {
        let text = "Rechnung fällig am 15.02.2025"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        #expect(events.first?.deadline != nil)
    }

    @Test("Parse English deadline keyword")
    func testEnglishDeadlineKeyword() throws {
        let text = "deadline 06/30/2025"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        #expect(events.first?.deadline != nil)
    }

    // MARK: - MHD (Best Before) Tests

    @Test("Parse MHD date")
    func testMHDDate() throws {
        let text = "MHD: 31.12.24"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)

        // MHD should be treated as deadline
        #expect(event.deadline != nil)

        if let deadline = event.deadline {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(components.day == 31)
            #expect(components.month == 12)
            #expect(components.year == 2024)
        }
    }

    // MARK: - Event Name Extraction Tests

    @Test("Extract event name from text")
    func testEventNameExtraction() throws {
        let text = "Amazon Prime payment 25.12.2024"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        #expect(event.name.contains("Amazon"))
    }

    @Test("Default reminder name when no text")
    func testDefaultReminderName() throws {
        let text = "25.12.2024"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        #expect(event.name == "Reminder")
    }

    // MARK: - Multiple Events Tests

    @Test("Parse multiple events from multiline text")
    func testMultipleEvents() throws {
        let text = """
        Amazon subscription 15.01.2025
        Netflix payment 20.01.2025
        Gym membership bis zum 31.01.2025
        """

        let events = parser.parseEvents(from: text)

        #expect(events.count == 3)

        // Check deadline detection for third event
        let gymEvent = events[2]
        #expect(gymEvent.deadline != nil)
    }

    @Test("Avoid duplicate dates")
    func testAvoidDuplicateDates() throws {
        let text = """
        Event on 25.12.2024
        Another event 25.12.2024
        """

        let events = parser.parseEvents(from: text)

        // Should only create one event for duplicate date
        #expect(events.count == 1)
    }

    // MARK: - Edge Cases

    @Test("Handle empty text")
    func testEmptyText() throws {
        let text = ""
        let events = parser.parseEvents(from: text)

        #expect(events.isEmpty)
    }

    @Test("Handle text without dates")
    func testTextWithoutDates() throws {
        let text = "This is just some random text without any dates"
        let events = parser.parseEvents(from: text)

        #expect(events.isEmpty)
    }

    @Test("Handle whitespace only")
    func testWhitespaceOnly() throws {
        let text = "   \n\n   \t   "
        let events = parser.parseEvents(from: text)

        #expect(events.isEmpty)
    }

    // MARK: - Regression Test for Bug Fix

    @Test("Regression: Simple date '25.12.2024' should parse correctly")
    func testRegressionSimpleDateParsing() throws {
        // This was the failing case that triggered the regex bug fix
        let text = "25.12.2024"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1, "Should extract one event from simple date")

        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 25, "Day should be 25")
        #expect(components.month == 12, "Month should be December (12)")
        #expect(components.year == 2024, "Year should be 2024")
    }

    @Test("Regression: Various simple date formats should work")
    func testRegressionVariousDateFormats() throws {
        let testCases = [
            ("01.01.2025", 1, 1, 2025),
            ("31.12.2024", 31, 12, 2024),
            ("15.06.25", 15, 6, 2025),
        ]

        for (text, expectedDay, expectedMonth, expectedYear) in testCases {
            let events = parser.parseEvents(from: text)

            #expect(events.count == 1, "Failed to parse: \(text)")

            if let event = events.first {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day, .month, .year], from: event.date)

                #expect(components.day == expectedDay, "Day mismatch for: \(text)")
                #expect(components.month == expectedMonth, "Month mismatch for: \(text)")
                #expect(components.year == expectedYear, "Year mismatch for: \(text)")
            }
        }
    }

    // MARK: - No Year Tests (Default to Current Year)

    @Test("Parse deadline without year - defaults to current year")
    func testDeadlineWithoutYear() throws {
        let text = "BLACK DEAL nur bis zum 02.12. 11 Uhr"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1, "Should extract one event from date without year")

        let event = try #require(events.first)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // Should have deadline
        #expect(event.deadline != nil, "Should have deadline set")

        if let deadline = event.deadline {
            let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(deadlineComponents.day == 2, "Deadline day should be 2")
            #expect(deadlineComponents.month == 12, "Deadline month should be December (12)")
            #expect(deadlineComponents.year == currentYear, "Deadline year should default to current year")
        }

        // Event name should be extracted
        #expect(event.name.contains("BLACK DEAL"), "Event name should contain 'BLACK DEAL'")
    }

    @Test("Parse fällig without year")
    func testFaelligWithoutYear() throws {
        let text = "Zahlung fällig am 15.03."
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        #expect(event.deadline != nil)

        if let deadline = event.deadline {
            let components = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(components.day == 15)
            #expect(components.month == 3)
            #expect(components.year == currentYear)
        }
    }

    @Test("Parse English deadline without year")
    func testEnglishDeadlineWithoutYear() throws {
        let text = "Payment deadline 12/25"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        #expect(event.deadline != nil)

        if let deadline = event.deadline {
            let components = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(components.day == 25)
            #expect(components.month == 12)
            #expect(components.year == currentYear)
        }
    }

    @Test("Parse English date without year (no keyword)")
    func testEnglishDateWithoutYear() throws {
        let text = "Meeting on 6/15"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        let components = calendar.dateComponents([.day, .month, .year], from: event.date)
        #expect(components.day == 15)
        #expect(components.month == 6)
        #expect(components.year == currentYear)

        // Should not be a deadline (no keyword)
        #expect(event.deadline == nil)
    }

    // MARK: - Time Extraction Tests

    @Test("Parse German time with 'Uhr' (hour only)")
    func testGermanTimeHourOnly() throws {
        let text = "BLACK DEAL bis zum 02.12. 11 Uhr"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        // Event name should NOT contain "11 Uhr"
        #expect(!event.name.contains("11 Uhr"), "Event name should not contain time string")
        #expect(event.name.contains("BLACK DEAL"), "Event name should contain 'BLACK DEAL'")

        // Deadline should have time set to 11:00
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let components = calendar.dateComponents([.hour, .minute], from: deadline)
            #expect(components.hour == 11, "Hour should be 11")
            #expect(components.minute == 0, "Minute should be 0")
        }
    }

    @Test("Parse German time with minutes (14:30 Uhr)")
    func testGermanTimeWithMinutes() throws {
        let text = "Meeting 15.03.2025 14:30 Uhr"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        // Event name should NOT contain "14:30 Uhr"
        #expect(!event.name.contains("14:30"))
        #expect(!event.name.contains("Uhr"))

        // Date should have time set to 14:30
        let components = calendar.dateComponents([.hour, .minute], from: event.date)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    @Test("Parse German time with dot notation (14.30 Uhr)")
    func testGermanTimeDotNotation() throws {
        let text = "Zahlung fällig 25.12.2024 14.30 Uhr"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        // Deadline should have time set to 14:30
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let components = calendar.dateComponents([.hour, .minute], from: deadline)
            #expect(components.hour == 14)
            #expect(components.minute == 30)
        }
    }

    @Test("Parse English time with PM (3pm)")
    func testEnglishTimePM() throws {
        let text = "Meeting deadline 12/25/2024 3pm"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        // Deadline should have time converted to 24-hour (15:00)
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let components = calendar.dateComponents([.hour, .minute], from: deadline)
            #expect(components.hour == 15, "3pm should be 15:00 in 24-hour format")
            #expect(components.minute == 0)
        }
    }

    @Test("Parse English time with minutes (3:30pm)")
    func testEnglishTimeWithMinutesPM() throws {
        let text = "Deadline 6/15 3:30pm"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        // Deadline should have time set to 15:30
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let components = calendar.dateComponents([.hour, .minute], from: deadline)
            #expect(components.hour == 15)
            #expect(components.minute == 30)
        }
    }

    @Test("Parse English time with AM (9am)")
    func testEnglishTimeAM() throws {
        let text = "Meeting 12/25/2024 9am"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        let components = calendar.dateComponents([.hour, .minute], from: event.date)
        #expect(components.hour == 9)
        #expect(components.minute == 0)
    }

    @Test("Parse 24-hour format (14:30)")
    func test24HourFormat() throws {
        let text = "Concert 25.12.2024 14:30"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        let components = calendar.dateComponents([.hour, .minute], from: event.date)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    @Test("Parse midnight 12am correctly")
    func testMidnight() throws {
        let text = "Event 25.12.2024 12am"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        let components = calendar.dateComponents([.hour, .minute], from: event.date)
        #expect(components.hour == 0, "12am should be 00:00")
        #expect(components.minute == 0)
    }

    @Test("Parse noon 12pm correctly")
    func testNoon() throws {
        let text = "Lunch 25.12.2024 12pm"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current

        let components = calendar.dateComponents([.hour, .minute], from: event.date)
        #expect(components.hour == 12, "12pm should be 12:00")
        #expect(components.minute == 0)
    }

    @Test("Real-world example: BLACK DEAL with time")
    func testRealWorldBlackDeal() throws {
        let text = "BLACK DEAL nur bis zum 02.12. 11 Uhr"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)

        let event = try #require(events.first)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // Event name should contain BLACK DEAL and NOT contain time
        #expect(event.name.contains("BLACK DEAL"), "Event name should contain 'BLACK DEAL'")
        #expect(!event.name.contains("11 Uhr"), "Event name should not contain '11 Uhr'")
        #expect(!event.name.contains("02.12"), "Event name should not contain date")

        // Deadline should be Dec 2, 2025 at 11:00
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: deadline)
            #expect(components.year == currentYear)
            #expect(components.month == 12)
            #expect(components.day == 2)
            #expect(components.hour == 11)
            #expect(components.minute == 0)
        }
    }

    // MARK: - Real-World Test Cases (from actual screenshots)

    @Test("App subscription: Starting on date (English)")
    func testAppSubscriptionEnglish() throws {
        let text = "38,99 € per year Starting on 13 Jan 2026"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 13)
        #expect(components.month == 1)
        #expect(components.year == 2026)
    }

    @Test("App subscription: Ab dem date (German)")
    func testAppSubscriptionGerman() throws {
        let text = "38,99 € pro Jahr Ab dem 13.01.2026"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 13)
        #expect(components.month == 1)
        #expect(components.year == 2026)
    }

    @Test("App subscription: Continues date")
    func testAppSubscriptionContinues() throws {
        let text = "Continues 6 April"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 6)
        #expect(components.month == 4)
        #expect(components.year == currentYear)
    }

    @Test("Amazon Prime: Renewal Date (English)")
    func testAmazonPrimeRenewalEnglish() throws {
        let text = "Renewal Date 21 January 2026"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        // Event date should be the actual renewal date
        #expect(components.day == 21)
        #expect(components.month == 1)
        #expect(components.year == 2026)

        // Deadline should match
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(deadlineComponents.day == 21)
            #expect(deadlineComponents.month == 1)
            #expect(deadlineComponents.year == 2026)
        }
    }

    @Test("Amazon Prime: Nächste Zahlung (German)")
    func testAmazonPrimeRenewalGerman() throws {
        let text = "Nächste Zahlung 21. Januar 2026"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 21)
        #expect(components.month == 1)
        #expect(components.year == 2026)
    }

    @Test("Concert: German format with time")
    func testConcertGermanFormat() throws {
        let text = "18.05.26 in Berlin • Einlass: 19:00, Beginn: 20:00"
        let events = parser.parseEvents(from: text)

        #expect(events.count >= 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year, .hour, .minute], from: event.date)

        #expect(components.day == 18)
        #expect(components.month == 5)
        #expect(components.year == 2026)
        // Time could be 19:00 or 20:00 depending on parsing
    }

    @Test("Concert: Instagram story format")
    func testConcertInstagramStory() throws {
        let text = "TierPark Sessions 21.06.2025 📅 7PM Doors 🕖"
        let events = parser.parseEvents(from: text)

        #expect(events.count >= 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 21)
        #expect(components.month == 6)
        #expect(components.year == 2025)
    }

    @Test("Concert: Eventim format with German month name and time")
    func testConcertEventimFormat() throws {
        let text = """
        20 Juni 2026
        Sa. 16:00
        BERLIN
        Die Schlagernacht des Jahres 2026 - DAS ORIGINAL
        Waldbühne Berlin
        """
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)

        // Event name should NOT contain time or date, should contain actual event text
        #expect(!event.name.contains("16:00"))
        #expect(!event.name.contains("Sa."))
        #expect(!event.name.contains("20 Juni"))
        #expect(event.name.contains("BERLIN") || event.name.contains("Schlagernacht"))

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year, .hour, .minute], from: event.date)

        // Event date should be 20 Jun 2026 at 16:00 (time extracted from "Sa. 16:00")
        #expect(components.day == 20)
        #expect(components.month == 6)
        #expect(components.year == 2026)
        #expect(components.hour == 16)
        #expect(components.minute == 0)

        // TODO: In future, concerts should be treated as deadlines (reminder 24h before)
        // For now, they're regular events (no deadline)
    }

    @Test("Food expiry: zu verbrauchen bis")
    func testFoodExpiryZuVerbrauchenBis() throws {
        // Full OCR text from chicken packaging with price, weight, etc.
        let text = """
        Hähnchen-Innenfilet frisch
        bei max. +4°C zu verbrauchen bis:
        Festgewicht
        . €/kg
        30.12.25
        e400g
        12,4
        Preis
        4,99
        """
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        // Event date should be the actual expiry date
        #expect(components.day == 30)
        #expect(components.month == 12)
        #expect(components.year == 2025)

        // Deadline should match
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(deadlineComponents.day == 30)
            #expect(deadlineComponents.month == 12)
            #expect(deadlineComponents.year == 2025)
        }
    }

    @Test("Food expiry: Short date on cheese")
    func testFoodExpiryCheeseShortDate() throws {
        // Full OCR text from cheese packaging with nutrition score
        let text = """
        26.02.26
        LOS329
        NUTRI-SCORE
        A B
        DE
        edeka.de/nutri-score
        Weidechart
        """
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 26)
        #expect(components.month == 2)
        #expect(components.year == 2026)
    }

    @Test("Food expiry: MINDESTENS HALTBAR BIS")
    func testFoodExpiryMindestensHaltbarBis() throws {
        // Full OCR text from eggs packaging with batch codes
        let text = """
        MINDESTENS HALTBAR BIS:
        23.01.
        PN DE-1201
        Geu.Kl.:
        11417231075
        M
        """
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        // Event date should be the actual expiry date
        #expect(components.day == 23)
        #expect(components.month == 1)
        #expect(components.year == currentYear)

        // Should have deadline set
        #expect(event.deadline != nil)
        if let deadline = event.deadline {
            let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
            #expect(deadlineComponents.day == 23)
            #expect(deadlineComponents.month == 1)
            #expect(deadlineComponents.year == currentYear)
        }
    }

    @Test("Food expiry: Condensed milk can format")
    func testFoodExpiryCondensedMilk() throws {
        let text = "21.08.2026 L04"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: event.date)

        #expect(components.day == 21)
        #expect(components.month == 8)
        #expect(components.year == 2026)
    }

    // MARK: - Multi-line Event Name Extraction Tests

    @Test("Cinema ticket: Event name on line before date")
    func testCinemaTicketNameBeforeDate() throws {
        let text = """
        The Batman
        18.05.2026 19:00
        Cinestar Berlin
        """
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)

        // Name should include "The Batman" from the line above the date
        #expect(event.name.contains("The Batman"), "Event name should contain 'The Batman' from line before date, got: '\(event.name)'")
    }

    @Test("Concert poster: Title above date")
    func testConcertPosterTitleAboveDate() throws {
        let text = """
        Radiohead
        Live in Concert
        25.07.2026 20:00
        Waldbühne Berlin
        """
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)

        // Name should capture text from lines before the date
        #expect(event.name.contains("Radiohead") || event.name.contains("Live in Concert"),
                "Event name should contain title from lines above date, got: '\(event.name)'")
    }

    @Test("Same-line name still works")
    func testSameLineNameStillWorks() throws {
        let text = "Amazon Prime payment 25.12.2026"
        let events = parser.parseEvents(from: text)

        #expect(events.count == 1)
        let event = try #require(events.first)
        #expect(event.name.contains("Amazon"), "Same-line name extraction should still work, got: '\(event.name)'")
    }

    // MARK: - Real-World Dataset Analysis

    private struct DatasetTestCase: Codable {
        let id: String
        let category: String
        let text: String
        let expectedEvents: Int
        let expectedDate: ExpectedDate?
        let hasDeadline: Bool
    }

    private struct ExpectedDate: Codable {
        let day: Int
        let month: Int
        let year: YearValue

        enum YearValue: Codable {
            case int(Int)
            case string(String)

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let intVal = try? container.decode(Int.self) {
                    self = .int(intVal)
                } else if let strVal = try? container.decode(String.self) {
                    self = .string(strVal)
                } else {
                    throw DecodingError.typeMismatch(YearValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .int(let v): try container.encode(v)
                case .string(let v): try container.encode(v)
                }
            }

            var resolvedYear: Int {
                switch self {
                case .int(let v): return v
                case .string: return Calendar.current.component(.year, from: Date())
                }
            }
        }
    }

    private struct DatasetContainer: Codable {
        let testCases: [DatasetTestCase]
    }

    @Test("Real-world dataset analysis — 305 cases")
    func testRealWorldDatasetAnalysis() throws {
        let url = Bundle(for: BundleToken.self).url(forResource: "RealWorldTestCases", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let container = try JSONDecoder().decode(DatasetContainer.self, from: data)
        let testCases = container.testCases
        let calendar = Calendar.current

        struct FailureDetail {
            let id: String
            let category: String
            let text: String
            let reasons: [String]
            let rootCause: String
            let gotEvents: Int
            let expectedEvents: Int
            let gotDate: String
            let expectedDate: String
            let gotDeadline: String
        }

        var totalPassed = 0
        var totalFailed = 0
        var categoryResults: [String: (passed: Int, failed: Int)] = [:]
        var failures: [FailureDetail] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        for tc in testCases {
            let events = parser.parseEvents(from: tc.text)
            var passed = true
            var reasons: [String] = []
            var rootCause = ""
            var gotDateStr = "-"
            var gotDeadlineStr = "none"

            if tc.expectedEvents == 0 {
                if !events.isEmpty {
                    passed = false
                    reasons.append("Expected 0 events, got \(events.count)")
                    rootCause = "false_positive"
                    gotDateStr = dateFormatter.string(from: events[0].date)
                }
            } else {
                if events.isEmpty {
                    passed = false
                    reasons.append("Expected \(tc.expectedEvents) event(s), got 0")
                    rootCause = "no_extraction"
                } else {
                    let event = events[0]
                    gotDateStr = dateFormatter.string(from: event.date)
                    if let dl = event.deadline { gotDeadlineStr = dateFormatter.string(from: dl) }

                    if let expectedDate = tc.expectedDate {
                        let dateToCheck = tc.hasDeadline ? (event.deadline ?? event.date) : event.date
                        let comps = calendar.dateComponents([.day, .month, .year], from: dateToCheck)

                        let dayOff = comps.day != expectedDate.day
                        let monthOff = comps.month != expectedDate.month
                        let expectedYear = expectedDate.year.resolvedYear
                        let yearOff = comps.year != expectedYear

                        if dayOff {
                            passed = false
                            reasons.append("Day: expected \(expectedDate.day), got \(comps.day ?? -1)")
                        }
                        if monthOff {
                            passed = false
                            reasons.append("Month: expected \(expectedDate.month), got \(comps.month ?? -1)")
                        }
                        if yearOff {
                            passed = false
                            reasons.append("Year: expected \(expectedYear), got \(comps.year ?? -1)")
                        }

                        if !passed && rootCause.isEmpty {
                            if monthOff || yearOff {
                                rootCause = "wrong_date_picked"
                            } else if dayOff {
                                let diff = (comps.day ?? 0) - expectedDate.day
                                rootCause = abs(diff) == 1 ? "off_by_one" : "wrong_date_picked"
                            }
                        }
                    }

                    if tc.hasDeadline && events[0].deadline == nil {
                        passed = false
                        reasons.append("Expected deadline but none found")
                        if rootCause.isEmpty {
                            rootCause = "missing_deadline_flag"
                        } else {
                            rootCause += "+missing_deadline"
                        }
                    }
                }
            }

            let cat = tc.category
            let prev = categoryResults[cat] ?? (0, 0)

            if passed {
                totalPassed += 1
                categoryResults[cat] = (prev.passed + 1, prev.failed)
            } else {
                totalFailed += 1
                categoryResults[cat] = (prev.passed, prev.failed + 1)
                let expectedDateStr: String
                if let ed = tc.expectedDate {
                    expectedDateStr = String(format: "%02d.%02d.%d", ed.day, ed.month, ed.year.resolvedYear)
                } else {
                    expectedDateStr = "-"
                }
                failures.append(FailureDetail(
                    id: tc.id, category: cat,
                    text: String(tc.text.prefix(60)).replacingOccurrences(of: "\n", with: " "),
                    reasons: reasons, rootCause: rootCause,
                    gotEvents: events.count, expectedEvents: tc.expectedEvents,
                    gotDate: gotDateStr, expectedDate: expectedDateStr,
                    gotDeadline: gotDeadlineStr
                ))
            }
        }

        let total = totalPassed + totalFailed
        let pct = total > 0 ? Double(totalPassed) / Double(total) * 100.0 : 0

        var rootCauseCounts: [String: Int] = [:]
        for f in failures { rootCauseCounts[f.rootCause, default: 0] += 1 }

        var r = "\n"
        r += "╔══════════════════════════════════════════════════════════════════╗\n"
        r += "║            TAKT PARSER — REAL-WORLD DATASET ANALYSIS            ║\n"
        r += "╚══════════════════════════════════════════════════════════════════╝\n\n"

        let barLen = 40
        let filledLen = Int(Double(barLen) * pct / 100.0)
        let bar = String(repeating: "█", count: filledLen) + String(repeating: "░", count: barLen - filledLen)
        r += "  OVERALL: \(totalPassed)/\(total) passed (\(String(format: "%.1f", pct))%)\n"
        r += "  [\(bar)]\n\n"

        r += "  ┌─────────────────────────┬───────┬────────┬────────┬────────┐\n"
        r += "  │ Category                │ Total │ Passed │ Failed │   Rate │\n"
        r += "  ├─────────────────────────┼───────┼────────┼────────┼────────┤\n"
        for (cat, result) in categoryResults.sorted(by: { $0.key < $1.key }) {
            let catTotal = result.passed + result.failed
            let catPct = catTotal > 0 ? Double(result.passed) / Double(catTotal) * 100.0 : 0
            let icon = result.failed == 0 ? "+" : "x"
            let catName = cat.padding(toLength: 21, withPad: " ", startingAt: 0)
            r += "  │ \(icon) \(catName) │  \(String(format: "%3d", catTotal))  │   \(String(format: "%3d", result.passed))  │   \(String(format: "%3d", result.failed))  │ \(String(format: "%4.0f", catPct))%  │\n"
        }
        r += "  ├─────────────────────────┼───────┼────────┼────────┼────────┤\n"
        r += "  │ TOTAL                   │  \(String(format: "%3d", total))  │   \(String(format: "%3d", totalPassed))  │   \(String(format: "%3d", totalFailed))  │ \(String(format: "%4.0f", pct))%  │\n"
        r += "  └─────────────────────────┴───────┴────────┴────────┴────────┘\n\n"

        r += "  ROOT CAUSE BREAKDOWN:\n"
        r += "  ┌──────────────────────────────────┬───────┬────────┐\n"
        r += "  │ Root Cause                       │ Count │   Pct  │\n"
        r += "  ├──────────────────────────────────┼───────┼────────┤\n"
        for (cause, count) in rootCauseCounts.sorted(by: { $0.value > $1.value }) {
            let causePct = Double(count) / Double(totalFailed) * 100.0
            let causeName: String
            switch cause {
            case "off_by_one": causeName = "Off-by-one day"
            case "off_by_one+missing_deadline": causeName = "Off-by-one + no deadline"
            case "no_extraction": causeName = "No events extracted"
            case "wrong_date_picked": causeName = "Wrong date selected"
            case "wrong_date_picked+missing_deadline": causeName = "Wrong date + no deadline"
            case "false_positive": causeName = "False positive (ghost event)"
            case "missing_deadline_flag": causeName = "Missing deadline flag"
            default: causeName = cause
            }
            r += "  │ \(causeName.padding(toLength: 32, withPad: " ", startingAt: 0)) │  \(String(format: "%3d", count))  │ \(String(format: "%4.0f", causePct))%  │\n"
        }
        r += "  └──────────────────────────────────┴───────┴────────┘\n\n"

        if !failures.isEmpty {
            r += "  DETAILED FAILURES (\(failures.count)):\n"
            r += "  ┌───────────────────────────────────┬──────────────┬──────────────┬──────────────┬──────────────────────────────┐\n"
            r += "  │ Test ID                           │ Expected     │ Got          │ Deadline     │ Root Cause                   │\n"
            r += "  ├───────────────────────────────────┼──────────────┼──────────────┼──────────────┼──────────────────────────────┤\n"
            for f in failures {
                let id = f.id.padding(toLength: 33, withPad: " ", startingAt: 0)
                let expected = (f.expectedEvents == 0 ? "0 events" : f.expectedDate).padding(toLength: 12, withPad: " ", startingAt: 0)
                let got = (f.gotEvents == 0 ? "0 events" : f.gotDate).padding(toLength: 12, withPad: " ", startingAt: 0)
                let dl = f.gotDeadline.padding(toLength: 12, withPad: " ", startingAt: 0)
                let cause = f.rootCause.padding(toLength: 28, withPad: " ", startingAt: 0)
                r += "  │ \(id) │ \(expected) │ \(got) │ \(dl) │ \(cause) │\n"
            }
            r += "  └───────────────────────────────────┴──────────────┴──────────────┴──────────────┴──────────────────────────────┘\n\n"

            r += "  FAILURE INPUT TEXTS:\n"
            r += "  " + String(repeating: "─", count: 90) + "\n"
            for f in failures {
                r += "  [\(f.category)] \(f.id)\n"
                r += "  Input: \"\(f.text)\"\n"
                r += "  Issue: \(f.reasons.joined(separator: " | "))\n"
                r += "  " + String(repeating: "─", count: 90) + "\n"
            }
        }

        r += "\n"
        try? r.write(toFile: "/tmp/takt_dataset_analysis.txt", atomically: true, encoding: .utf8)
        print(r)
    }
}

private class BundleToken {}
