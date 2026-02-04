//
//  ScanViewModel.swift
//  Takt
//
//  Created by Artem Alekseev on 27.12.25.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ScanViewModel {

    // MARK: - State

    // Input state
    var selectedImageData: Data?
    var inputText: String = ""

    // Processing state
    var isProcessing: Bool = false
    var showProgressIndicator: Bool = false // Only shown after 2 seconds

    // Extracted events
    var extractedEvents: [Event] = []
    var currentEventIndex: Int = 0
    
    // Draft for editing
    var currentDraft: Event?

    // UI state
    var showSuccessToast: Bool = false
    var errorMessage: String?

    // MARK: - Computed Properties

    var hasExtractedEvents: Bool {
        !extractedEvents.isEmpty
    }

    var currentEvent: Event? {
        guard currentEventIndex < extractedEvents.count else { return nil }
        return extractedEvents[currentEventIndex]
    }
    
    var displayEvent: Event? {
        currentDraft ?? currentEvent
    }

    var eventCounter: String {
        guard hasExtractedEvents else { return "" }
        return "\(currentEventIndex + 1)/\(extractedEvents.count)"
    }

    var hasError: Bool {
        errorMessage != nil
    }

    // MARK: - Dependencies

    private let textRecognitionService: TextRecognitionServiceProtocol
    private let textEventParserService: TextEventParserServiceProtocol
    private let addEventUseCase: AddEventUseCaseProtocol

    // MARK: - Init

    init(
        textRecognitionService: TextRecognitionServiceProtocol,
        textEventParserService: TextEventParserServiceProtocol,
        addEventUseCase: AddEventUseCaseProtocol
    ) {
        self.textRecognitionService = textRecognitionService
        self.textEventParserService = textEventParserService
        self.addEventUseCase = addEventUseCase
    }

    // MARK: - Actions

    /// Process image: OCR → Parse → Extract events
    func processImage() async {
        guard let imageData = selectedImageData else {
            errorMessage = "No image selected"
            return
        }

        isProcessing = true
        errorMessage = nil
        extractedEvents = []

        // Start 2-second timer for progress indicator
        let progressTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled && isProcessing {
                showProgressIndicator = true
            }
        }

        defer {
            isProcessing = false
            showProgressIndicator = false
            progressTask.cancel()
        }

        do {
            // Step 1: OCR
            let recognizedText = try await textRecognitionService.recognizeText(fromImageData: imageData)

            guard !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "No text found in image"
                return
            }

            // Step 2: Parse events
            let events = try textEventParserService.parseEvents(from: recognizedText)

            guard !events.isEmpty else {
                errorMessage = "No events with dates found in the text"
                return
            }

            extractedEvents = events
            currentEventIndex = 0

        } catch {
            errorMessage = "Failed to process image: \(error.localizedDescription)"
        }
    }

    /// Process text directly: Parse → Extract events
    func processText() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            errorMessage = "Please enter some text"
            return
        }

        isProcessing = true
        errorMessage = nil
        extractedEvents = []

        // Start 2-second timer for progress indicator
        let progressTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled && isProcessing {
                showProgressIndicator = true
            }
        }

        defer {
            isProcessing = false
            showProgressIndicator = false
            progressTask.cancel()
        }

        do {
            let events = try textEventParserService.parseEvents(from: text)

            guard !events.isEmpty else {
                errorMessage = "No events with dates found in the text"
                return
            }

            extractedEvents = events
            currentEventIndex = 0

        } catch {
            errorMessage = "Failed to process text: \(error.localizedDescription)"
        }
    }
    
    func ensureDraft() {
        if currentDraft == nil {
            currentDraft = currentEvent
        }
    }

    /// Save current event and move to next (or finish)
    func saveCurrentEvent() async {
        guard let event = currentDraft ?? currentEvent else { return }

        do {
            try await addEventUseCase.execute(event)

            // Show success feedback
            showSuccessToast = true
            currentDraft = nil

            // Move to next event or finish
            if currentEventIndex < extractedEvents.count - 1 {
                currentEventIndex += 1
            } else {
                // All events processed - reset after a delay for toast to show
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    reset()
                }
            }

        } catch {
            errorMessage = "Failed to save event: \(error.localizedDescription)"
        }
    }

    /// Skip current event without saving
    func skipCurrentEvent() {
        currentDraft = nil
        
        if currentEventIndex < extractedEvents.count - 1 {
            currentEventIndex += 1
        } else {
            // Last event - reset
            reset()
        }
    }

    /// Cancel all remaining events and return to scan
    func cancelAll() {
        reset()
    }

    /// Reset to initial state
    func reset() {
        selectedImageData = nil
        inputText = ""
        extractedEvents = []
        currentEventIndex = 0
        currentDraft = nil
        errorMessage = nil
        showSuccessToast = false
        isProcessing = false
        showProgressIndicator = false
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Dismiss success toast
    func dismissToast() {
        showSuccessToast = false
    }

    /// Paste text from clipboard
    func pasteFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            inputText = clipboardText
        } else {
            errorMessage = "No text found in clipboard"
        }
    }
}
