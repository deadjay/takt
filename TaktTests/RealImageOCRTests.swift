import Testing
import Foundation
@testable import Takt

/// Tests using REAL images with actual Vision OCR
/// These tests validate the full pipeline with real-world photos
@Suite("Real Image OCR Tests", .serialized)
struct RealImageOCRTests {

    // MARK: - Helper Methods

    private func loadImageData(named filename: String) throws -> Data {
        // For Swift Testing framework, find the test bundle
        let bundles = Bundle.allBundles

        print("Looking for image: \(filename)")
        print("Searching in \(bundles.count) bundles")

        // Try to find the test bundle and look for the image
        for bundle in bundles {
            print("Checking bundle: \(bundle.bundlePath)")
            if let url = bundle.url(forResource: filename, withExtension: nil, subdirectory: "TestImages") {
                print("Found in TestImages subdirectory!")
                return try Data(contentsOf: url)
            }
        }

        // If not found in subdirectory, try without subdirectory
        for bundle in bundles {
            if let url = bundle.url(forResource: filename, withExtension: nil) {
                print("Found without subdirectory!")
                return try Data(contentsOf: url)
            }
        }

        // Try direct path as last resort
        let directPath = "/Users/deadjay/Repos/Takt/TaktTests/Resources/TestImages/\(filename)"
        if FileManager.default.fileExists(atPath: directPath) {
            print("Found at direct path!")
            return try Data(contentsOf: URL(fileURLWithPath: directPath))
        }

        print("Image not found anywhere!")
        throw TestError.imageNotFound(filename)
    }

    private func makeTextRecognitionService() -> TextRecognitionServiceProtocol {
        return DefaultTextRecognitionService()
    }

    private func makeTextEventParser() -> TextEventParserServiceProtocol {
        return TextEventParser()
    }

    /// Cleanup helper to release Vision framework resources between tests
    private func cleanupAfterOCR() async throws {
        // Small delay to let Vision framework release memory and resources
        // Prevents simulator crashes when running all tests together
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
    }

    enum TestError: Error {
        case imageNotFound(String)
        case testBundleNotFound
    }

    // MARK: - Subscription Tests

    @Test("Real OCR: one sec pro subscription")
    func testOneSecPro() async throws {
        let imageData = try loadImageData(named: "oneSecPro.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("one sec pro OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find subscription date")

        // Expected: Starting on 6 Apr 2026
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 6, "Expected day 6")
            #expect(components.month == 4, "Expected month April (4)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Fabulous subscription (English)")
    func testFabulousEN() async throws {
        let imageData = try loadImageData(named: "FabulousAppEN.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Fabulous EN OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find subscription date")

        // Expected: Starting on 13 Jan 2026
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 13, "Expected day 13")
            #expect(components.month == 1, "Expected month January (1)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Fabulous subscription (German)")
    func testFabulousDE() async throws {
        let imageData = try loadImageData(named: "fabulousAboDE.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Fabulous DE OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find subscription date")

        // Expected: Ab dem 13.01.2026
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 13, "Expected day 13")
            #expect(components.month == 1, "Expected month January (1)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Amazon subscription (App)")
    func testAmazonSubscriptionApp() async throws {
        let imageData = try loadImageData(named: "amazonSubscriptionApp.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Amazon App OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find subscription renewal date")

        // Expected: 21.01.2026 renewal date (deadline)
        if let event = events.first {
            // Check if it's set as deadline or regular date
            let dateToCheck = event.deadline ?? event.date
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: dateToCheck)
            #expect(components.day == 21, "Expected day 21")
            #expect(components.month == 1, "Expected month January (1)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Amazon subscription (Web)")
    func testAmazonSubscriptionWeb() async throws {
        let imageData = try loadImageData(named: "amazonSubscriptionWeb.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Amazon Web OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find subscription renewal date")

        // Expected: 21.01.2026 renewal date (deadline)
        if let event = events.first {
            // Check if it's set as deadline or regular date
            let dateToCheck = event.deadline ?? event.date
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: dateToCheck)
            #expect(components.day == 21, "Expected day 21")
            #expect(components.month == 1, "Expected month January (1)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Multiple subscriptions")
    func testSubscriptions() async throws {
        let imageData = try loadImageData(named: "subsriptions.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Subscriptions OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        // Expected: Multiple subscriptions with various dates
        // - Amazon Prime: 21.01.2026
        // - YouTube Premium: 20.02.2026
        // - ChatGPT Plus: 05.01.2026
        // - one sec pro: 06.04.2026
        #expect(events.count >= 4, "Should find at least 4 subscription dates")

        // Verify we found the expected dates
        let calendar = Calendar.current
        let dateStrings = events.map { event in
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            return "\(components.day!).\(components.month!).\(components.year!)"
        }

        // Check that we have the expected dates (order may vary)
        let expectedDates = ["21.1.2026", "20.2.2026", "5.1.2026", "6.4.2026"]
        for expected in expectedDates {
            #expect(dateStrings.contains(expected), "Should find date \(expected)")
        }

        try await cleanupAfterOCR()
    }

    // MARK: - Concert Tests

    @Test("Real OCR: Deerhoof concert")
    func testDeerhoofConcert() async throws {
        let imageData = try loadImageData(named: "DeerhoofLive.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Deerhoof OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find concert date")

        // Expected: 18.05.26 (18 May 2026)
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 18, "Expected day 18")
            #expect(components.month == 5, "Expected month May (5)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Deerhoof concert variant 1")
    func testDeerhoofConcert1() async throws {
        let imageData = try loadImageData(named: "DeerhoofLive1.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Deerhoof1 OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find concert date")

        // Expected: 18.05.2026, Berlin Germany, SO36
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 18, "Expected day 18")
            #expect(components.month == 5, "Expected month May (5)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Deerhoof concert variant 2")
    func testDeerhoofConcert2() async throws {
        let imageData = try loadImageData(named: "DeerhoofLive2.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Deerhoof2 OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find concert date and time")

        // Expected: 18.05.2026 20:00, Berlin Germany, SO36
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year, .hour], from: event.date)
            #expect(components.day == 18, "Expected day 18")
            #expect(components.month == 5, "Expected month May (5)")
            #expect(components.year == 2026, "Expected year 2026")
            // Note: Time may or may not be extracted, depends on parser implementation
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Rundfunk concert poster")
    func testRundfunkKonzert() async throws {
        let imageData = try loadImageData(named: "RundfunkKonzert.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Rundfunk Konzert OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find concert date")

        // Expected: 11.01.2026 20:00 Rundfunk-Sinfonieorchester Berlin, Sinfoniekonzert
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 11, "Expected day 11")
            #expect(components.month == 1, "Expected month January (1)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Rundfunk tickets")
    func testRundfunkTickets() async throws {
        let imageData = try loadImageData(named: "RundfunkTickets.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Rundfunk Tickets OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find concert date")

        // Expected: 11.01.2026 20:00 Rundfunk-Sinfonieorchester Berlin, Philarmonie Berlin
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 11, "Expected day 11")
            #expect(components.month == 1, "Expected month January (1)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Stummfilm poster")
    func testStummfilmPoster() async throws {
        let imageData = try loadImageData(named: "stummfilmPoster.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Stummfilm OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find event date")

        // Expected: 10.01.2026 24:00 Stummfilm um Mitternacht
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 10, "Expected day 10")
            #expect(components.month == 1, "Expected month January (1)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    // MARK: - Food Expiry Tests

    @Test("Real OCR: Chicken (Hähnchen)")
    func testChicken() async throws {
        let imageData = try loadImageData(named: "haehnchen.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Chicken OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find expiry date")

        // Expected: zu verbrauchen bis: 30.12.25
        // Should create reminder on Dec 29, 2025 (1 day before deadline)
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 29, "Expected reminder day 29 (1 day before deadline)")
            #expect(components.month == 12, "Expected month December (12)")
            #expect(components.year == 2025, "Expected year 2025")

            // Verify deadline is set to Dec 30
            if let deadline = event.deadline {
                let deadlineComponents = calendar.dateComponents([.day, .month, .year], from: deadline)
                #expect(deadlineComponents.day == 30, "Expected deadline day 30")
                #expect(deadlineComponents.month == 12, "Expected deadline month December (12)")
                #expect(deadlineComponents.year == 2025, "Expected deadline year 2025")
            }
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Cheese (Käse)")
    func testCheese() async throws {
        let imageData = try loadImageData(named: "kaese.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Cheese OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find expiry date")

        // Expected: 26.02.26 (26 Feb 2026)
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 26, "Expected day 26")
            #expect(components.month == 2, "Expected month February (2)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Eggs (Eiern)")
    func testEggs() async throws {
        let imageData = try loadImageData(named: "eiern.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Eggs OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find expiry date")

        // Expected: MINDESTENS HALTBAR BIS: 23.01. (year missing, defaults to 2026)
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 23, "Expected day 23")
            #expect(components.month == 1, "Expected month January (1)")
            // Year should default to current year (2026)
            #expect(components.year == 2026, "Expected year 2026 (current year default)")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Condensed milk (Kondensmilch)")
    func testKondensmilch() async throws {
        let imageData = try loadImageData(named: "kondensmilch.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Kondensmilch OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find expiry date")

        // Expected: 21.08.2026
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 21, "Expected day 21")
            #expect(components.month == 8, "Expected month August (8)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Milk (Milch)")
    func testMilch() async throws {
        let imageData = try loadImageData(named: "milch.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Milch OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find expiry date")

        // Expected: 01.01 (no year, defaults to current year 2026)
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 1, "Expected day 1")
            #expect(components.month == 1, "Expected month January (1)")
            // Year should default to current year (2026)
            #expect(components.year == 2026, "Expected year 2026 (current year default)")
        }

        try await cleanupAfterOCR()
    }

    @Test("Real OCR: Juice (Saft)")
    func testSaft() async throws {
        let imageData = try loadImageData(named: "saft.jpeg")
        let ocrService = makeTextRecognitionService()
        let recognizedText = try await ocrService.recognizeText(fromImageData: imageData)

        print("Saft OCR:", recognizedText)

        let parser = makeTextEventParser()
        let events = try parser.parseEvents(from: recognizedText)

        #expect(events.count >= 1, "Should find expiry date")

        // Expected: 02.09.2026
        if let event = events.first {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: event.date)
            #expect(components.day == 2, "Expected day 2")
            #expect(components.month == 9, "Expected month September (9)")
            #expect(components.year == 2026, "Expected year 2026")
        }

        try await cleanupAfterOCR()
    }
}
