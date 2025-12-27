//
//  TextEventParserTests.swift
//  TaktTests
//
//  Created by Artem Alekseev on 27.12.25.
//

import Testing
import Foundation
@testable import Takt

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

        // Should create reminder 1 day before deadline
        #expect(components.day == 24)
        #expect(components.month == 12)
        #expect(components.year == 2024)

        // Should have deadline set
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

        #expect(components.day == 25)
        #expect(components.month == 12)
        #expect(components.year == 2024)
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
}
