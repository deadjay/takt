import Vision
import UIKit
import Foundation

@MainActor
class TextRecognitionService: ObservableObject {
    @Published var isProcessing = false
    @Published var extractedText = ""
    @Published var extractedEvent: Event?
    @Published var errorMessage: String?
    
    func recognizeText(from image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        
        guard let cgImage = image.cgImage else {
            errorMessage = "Failed to process image"
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Text recognition failed: \(error.localizedDescription)"
                    self?.isProcessing = false
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self?.errorMessage = "No text found in image"
                    self?.isProcessing = false
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self?.extractedText = fullText
                self?.parseEventFromText(fullText)
                self?.isProcessing = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            errorMessage = "Failed to process image: \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    private func parseEventFromText(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        
        var eventName = ""
        var eventDate: Date?
        var deadline: Date?
        
        // Try to find event name (usually the first meaningful line)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.matches(String.datePattern) && !trimmed.matches(String.timePattern) {
                eventName = trimmed
                break
            }
        }
        
        // Try to find dates
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for event date
            if eventDate == nil {
                if let date = parseDate(from: trimmed) {
                    eventDate = date
                    continue
                }
            }
            
            // Look for deadline
            if deadline == nil {
                if let date = parseDate(from: trimmed) {
                    deadline = date
                }
            }
        }
        
        // If we found a name and at least one date, create an event
        if !eventName.isEmpty && eventDate != nil {
            extractedEvent = Event(
                name: eventName,
                date: eventDate!,
                deadline: deadline
            )
        }
    }
    
    private func parseDate(from text: String) -> Date? {
        let formatters: [DateFormatter] = [
            createFormatter("MMM dd, yyyy"),
            createFormatter("MM/dd/yyyy"),
            createFormatter("dd/MM/yyyy"),
            createFormatter("yyyy-MM-dd"),
            createFormatter("MM-dd-yyyy"),
            createFormatter("dd-MM-yyyy"),
            createFormatter("MMM dd"),
            createFormatter("dd MMM"),
            createFormatter("MMM dd, yyyy 'at' h:mm a"),
            createFormatter("MMM dd, yyyy h:mm a"),
            createFormatter("MM/dd/yyyy h:mm a"),
            createFormatter("dd/MM/yyyy h:mm a")
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: text) {
                return date
            }
        }
        
        return nil
    }
    
    private func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}

// MARK: - Regex Patterns
private extension String {
    static var datePattern: String {
        return #"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})|(\w{3}\s+\d{1,2},?\s+\d{4})|(\d{4}-\d{2}-\d{2})"#
    }

    static var timePattern: String {
        return #"(\d{1,2}:\d{2}\s*[AP]M)|(\d{1,2}:\d{2})"#
    }

    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}
