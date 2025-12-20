//
//  ContentViewModel.swift
//  Takt
//
//  Created by Artem Alekseev on 17.12.25.
//

import Foundation
import Observation

// MARK: - ContentViewModel (Presentation Layer)
// ViewModels must be framework-agnostic (no SwiftUI/UIKit imports). Use Data for image payloads.

@MainActor
@Observable
final class ContentViewModel {
    // MARK: State (observed by ContentView)
    var inputText: String = ""
    var selectedImageData: Data? = nil
    var isLoading: Bool = false
    var isShowingAddEventSheet: Bool = false
    var errorMessage: String? = nil

    // Domain entities displayed in UI
    var events: [Event] = []

    // Parsed, not-yet-persisted candidates
    var extractedEvents: [Event] = []

    // MARK: Helpers (UI State)
    private func resetDraftState() {
        extractedEvents.removeAll()
        inputText = ""
        selectedImageData = nil
        isShowingAddEventSheet = false
    }

    /// Call this from the view after presenting an error to clear it.
    func consumeError() {
        errorMessage = nil
    }

    // MARK: Dependencies
    private let getEventsUseCase: GetEventsUseCaseProtocol
    private let addEventUseCase: AddEventUseCaseProtocol
    private let updateEventUseCase: UpdateEventUseCaseProtocol
    private let deleteEventUseCase: DeleteEventUseCaseProtocol
    private let textRecognitionService: TextRecognitionServiceProtocol
    private let textParser: TextEventParserServiceProtocol

    // MARK: Init
    init(
        getEventsUseCase: GetEventsUseCaseProtocol,
        addEventUseCase: AddEventUseCaseProtocol,
        updateEventUseCase: UpdateEventUseCaseProtocol,
        deleteEventUseCase: DeleteEventUseCaseProtocol,
        textRecognitionService: TextRecognitionServiceProtocol,
        textParser: TextEventParserServiceProtocol
    ) {
        self.getEventsUseCase = getEventsUseCase
        self.addEventUseCase = addEventUseCase
        self.updateEventUseCase = updateEventUseCase
        self.deleteEventUseCase = deleteEventUseCase
        self.textRecognitionService = textRecognitionService
        self.textParser = textParser
    }

    // MARK: Lifecycle
    func onAppear() async {
        await loadEvents()
    }

    // MARK: Intents
    func loadEvents() async {
        isLoading = true
        defer { isLoading = false }
        do {
            events = try await getEventsUseCase.execute()
        } catch {
            errorMessage = localized(error)
        }
    }

    func setImageData(_ data: Data?) {
        selectedImageData = data
    }

    func processTextInput() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            extractedEvents = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            extractedEvents = try textParser.parseEvents(from: inputText)
            isShowingAddEventSheet = !extractedEvents.isEmpty
        } catch {
            errorMessage = localized(error)
        }
    }

    func processSelectedImage() async {
        guard let data = selectedImageData else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let recognizedText = try await textRecognitionService.recognizeText(fromImageData: data)
            guard !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                inputText = ""
                extractedEvents = []
                isShowingAddEventSheet = false
                return
            }
            inputText = recognizedText
            extractedEvents = try textParser.parseEvents(from: recognizedText)
            isShowingAddEventSheet = !extractedEvents.isEmpty
        } catch {
            errorMessage = localized(error)
        }
    }

    func confirmAdd(event: Event) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await addEventUseCase.execute(event)
            await loadEvents()
            resetDraftState()
        } catch {
            errorMessage = localized(error)
        }
    }

    func addAllExtracted() async {
        guard !extractedEvents.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            for ev in extractedEvents {
                try await addEventUseCase.execute(ev)
            }
            await loadEvents()
            resetDraftState()
        } catch {
            errorMessage = localized(error)
        }
    }

    func delete(at offsets: IndexSet) async {
        let toDelete = offsets.map { events[$0] }
        isLoading = true
        defer { isLoading = false }
        do {
            for ev in toDelete {
                try await deleteEventUseCase.execute(ev)
            }
            await loadEvents()
        } catch {
            errorMessage = localized(error)
        }
    }

    /// Updates an existing event via use case and refreshes the list from the repository.
    func update(event: Event) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await updateEventUseCase.execute(event)
            await loadEvents()
        } catch {
            errorMessage = localized(error)
        }
    }

    func cancelAdd() {
        isShowingAddEventSheet = false
    }

    // MARK: Helpers
    private func localized(_ error: Error) -> String {
        // Replace with a proper error mapper if needed
        (error as NSError).localizedDescription
    }
}
 
