//
//  TextInputViewModelTests.swift
//  Takt
//
//  Created by Artem Alekseev on 16.11.25.
//

import Testing
import Foundation
@testable import Takt

@Suite("TextInput ViewModel Tests")
struct TextInputViewModelTests {

    // MARK: - Mock Dependencies

    class MockTextRecognitionService: TextRecognitionServiceProtocol {
        func recognizeText(fromImageData imageData: Data) async throws -> String {
            return "Test text"
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
    func makeSUT() -> (viewModel: TextInputViewModel, mockUseCase: MockAddEventUseCase) {
        let mockOCR = MockTextRecognitionService()
        let mockUseCase = MockAddEventUseCase()

        let viewModel = TextInputViewModel(
            textRecognitionService: mockOCR,
            addEventUseCase: mockUseCase
        )

        return (viewModel, mockUseCase)
    }

    // MARK: - Tests

    @Test("Initial state is correct")
    @MainActor
    func testInitialState() async throws {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.inputText.isEmpty)
        #expect(viewModel.extractedEvents.isEmpty)
    }

    @Test("Process text with valid date")
    @MainActor
    func testProcessTextWithValidDate() async throws {
        let (viewModel, _) = makeSUT()

        viewModel.inputText = "Meeting on 25.12.2024"

        await viewModel.processText()

        #expect(viewModel.extractedEvents.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Process empty text shows error")
    @MainActor
    func testProcessEmptyText() async throws {
        let (viewModel, _) = makeSUT()

        viewModel.inputText = ""

        await viewModel.processText()

        #expect(viewModel.errorMessage == "Please enter some text")
        #expect(viewModel.extractedEvents.isEmpty)
    }

    @Test("Save all events calls use case")
    @MainActor
    func testSaveAllEvents() async throws {
        let (viewModel, mockUseCase) = makeSUT()

        // Create test events
        let event1 = Event(name: "Event 1", date: Date(), deadline: nil, notes: nil)
        let event2 = Event(name: "Event 2", date: Date(), deadline: nil, notes: nil)
        viewModel.extractedEvents = [event1, event2]

        await viewModel.saveAllEvents()

        #expect(mockUseCase.savedEvents.count == 2)
        #expect(viewModel.inputText.isEmpty)
        #expect(viewModel.extractedEvents.isEmpty)
    }
}
