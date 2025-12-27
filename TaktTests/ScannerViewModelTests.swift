//
//  ScanViewModelTests.swift
//  Takt
//
//  Created by Artem Alekseev on 14.11.25.
//

import Testing
import Foundation
@testable import Takt

@Suite("Scan ViewModel Tests")
struct ScanViewModelTests {

    // MARK: - Mock Dependencies

    class MockTextRecognitionService: TextRecognitionServiceProtocol {
        var shouldFail = false
        var mockText = "Test event 25.12.2024"

        func recognizeText(fromImageData imageData: Data) async throws -> String {
            if shouldFail {
                throw NSError(domain: "test", code: -1)
            }
            return mockText
        }
    }

    class MockTextEventParserService: TextEventParserServiceProtocol {
        var mockEvents: [Event] = []

        func parseEvents(from text: String) throws -> [Event] {
            return mockEvents
        }
    }

    class MockAddEventUseCase: AddEventUseCaseProtocol {
        var savedEvents: [Event] = []

        func execute(_ event: Event) async throws {
            savedEvents.append(event)
        }
    }

    // MARK: - Test Setup

    @MainActor
    func makeSUT() -> (
        viewModel: ScanViewModel,
        mockOCR: MockTextRecognitionService,
        mockParser: MockTextEventParserService,
        mockUseCase: MockAddEventUseCase
    ) {
        let mockOCR = MockTextRecognitionService()
        let mockParser = MockTextEventParserService()
        let mockUseCase = MockAddEventUseCase()

        let viewModel = ScanViewModel(
            textRecognitionService: mockOCR,
            textEventParserService: mockParser,
            addEventUseCase: mockUseCase
        )

        return (viewModel, mockOCR, mockParser, mockUseCase)
    }

    // MARK: - Tests

    @Test("Initial state is correct")
    @MainActor
    func testInitialState() async throws {
        let (viewModel, _, _, _) = makeSUT()

        #expect(viewModel.isProcessing == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.extractedEvents.isEmpty)
        #expect(viewModel.inputText.isEmpty)
    }

    @Test("Process text extracts events")
    @MainActor
    func testProcessText() async throws {
        let (viewModel, _, mockParser, _) = makeSUT()

        // Setup mock event
        let mockEvent = Event(
            name: "Test Event",
            date: Date(),
            deadline: nil,
            notes: nil
        )
        mockParser.mockEvents = [mockEvent]

        viewModel.inputText = "Test event 25.12.2024"

        await viewModel.processText()

        #expect(viewModel.extractedEvents.count == 1)
        #expect(viewModel.extractedEvents.first?.name == "Test Event")
    }

    @Test("Save current event calls use case")
    @MainActor
    func testSaveCurrentEvent() async throws {
        let (viewModel, _, mockParser, mockUseCase) = makeSUT()

        // Setup mock event
        let mockEvent = Event(
            name: "Test Event",
            date: Date(),
            deadline: nil,
            notes: nil
        )
        mockParser.mockEvents = [mockEvent]

        viewModel.inputText = "Test event 25.12.2024"
        await viewModel.processText()

        await viewModel.saveCurrentEvent()

        #expect(mockUseCase.savedEvents.count == 1)
        #expect(mockUseCase.savedEvents.first?.name == "Test Event")
    }
}
