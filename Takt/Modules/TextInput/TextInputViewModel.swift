//
//  TextInputViewModel.swift
//  Takt
//
//  Created by Artem Alekseev on 16.11.25.
//

import Foundation
import Observation
import UIKit

@Observable
final class TextInputViewModel {
    
    // MARK: - State
    
    var inputText: String = ""
    var extractedEvents: [Event] = []
    
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    // private let someUseCase: SomeUseCaseProtocol
    private let textRecognitionService: TextRecognitionService
    private let addEventUseCase: AddEventUseCaseProtocol
    
    // MARK: - Init
    init(
        textRecognitionService: TextRecognitionService,
        addEventUseCase: AddEventUseCaseProtocol
    ) {
        self.textRecognitionService = textRecognitionService
        self.addEventUseCase = addEventUseCase
    }
    
    // MARK: - Actions
    
    func processText() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text"
            return
        }

        isLoading = true
        errorMessage = nil
        extractedEvents = []
        
        defer { isLoading = false }
        
        // TODO: Parse text to extract events
        // For now, we'll use the existing TextRecognitionService's parsing logic
        // Later we'll refactor to a unified parser (AI/Apple frameworks/etc.)
        
        let parsedEvents = [Event]()
        
        guard !parsedEvents.isEmpty else {
            errorMessage = "No events with dates found in the text"
            return
        }
        
        extractedEvents = parsedEvents
    }
    
    @MainActor
    func saveAllEvents() async {
        for event in extractedEvents {
            do {
                try await addEventUseCase.execute(event)
            } catch {
                errorMessage = "Failed to save event: \(event.name)"
                return
            }
        }
        
        // Success - clear everything
        clearInput()
    }
    
    func clearInput() {
        inputText = ""
        extractedEvents = []
        errorMessage = nil
    }
    
    func pasteFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            inputText = clipboardText
        } else {
            errorMessage = "No text found in clipboard"
        }
    }
}
