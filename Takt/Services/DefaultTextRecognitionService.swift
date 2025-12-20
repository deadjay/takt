//
//  DefaultTextRecognitionService.swift
//  Takt
//
//  Created by Artem Alekseev on 20.12.25.
//

import Vision
import ImageIO

// MARK: - Errors
public enum TextRecognitionError: Error {
    case invalidImageData
    case noTextFound
    case visionFailed(String)
}

// MARK: - Default Implementation (no framework state, async/await)
public final class DefaultTextRecognitionService: TextRecognitionServiceProtocol {
    public func recognizeText(fromImageData data: Data) async throws -> String {
        // Decode Data -> CGImage (avoid UIKit dependency)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw TextRecognitionError.invalidImageData
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: TextRecognitionError.visionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(throwing: TextRecognitionError.noTextFound)
                    return
                }

                let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TextRecognitionError.visionFailed(error.localizedDescription))
            }
        }
    }
}
