//
//  DefaultTextRecognitionService.swift
//  Takt
//
//  Created by Artem Alekseev on 20.12.25.
//

import Vision
import ImageIO
import CoreGraphics

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

        // Smart retry strategy:
        // 1. Try full image upscaling first
        // 2. If parser can't find any dates, retry with center crop + zoom

        let fullImage = upscaleIfNeeded(cgImage)
        let fullImageText = try await performOCR(on: fullImage, mode: .accurate)

        // Check if we found any date-like content (day+month or weekday)
        if containsDateIndicators(fullImageText) {
            return fullImageText
        }

        // No dates found - try center crop + zoom (mimics manual Preview workflow)
        print("⚠️ No dates detected in full image OCR, retrying with center crop + zoom...")
        if let croppedImage = centerCropAndZoom(cgImage, cropRatio: 0.6, zoomFactor: 3.0) {
            let croppedImageText = try await performOCR(on: croppedImage, mode: .accurate)
            print("📸 Center crop OCR result: \(croppedImageText.prefix(100))")
            return croppedImageText
        }

        // If center crop fails, return original full image result
        return fullImageText
    }

    /// Check if text contains any dates that NSDataDetector can parse
    /// More strict than the parser - we validate the context around matches
    private func containsDateIndicators(_ text: String) -> Bool {
        // Use NSDataDetector to find potential dates
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return false
        }

        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))

        // Validate each match to avoid false positives from garbage OCR
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let matchedText = String(text[range])

            // Check context: Look at the character BEFORE the match
            // Reject if preceded by a digit (e.g., "92:09.2" where NSDataDetector matches "09.2")
            let matchStartIndex = text.distance(from: text.startIndex, to: range.lowerBound)
            if matchStartIndex > 0 {
                let precedingIndex = text.index(text.startIndex, offsetBy: matchStartIndex - 1)
                let precedingChar = text[precedingIndex]
                // Reject if preceded by digit or colon (indicates OCR garbage like "92:09.2")
                if precedingChar.isNumber || precedingChar == ":" {
                    continue
                }
            }

            // Quick validation: Check if matched text starts with reasonable date indicators
            let lowercased = matchedText.lowercased()

            // Valid weekday names
            let weekdays = ["montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", "sonntag",
                           "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
                           "mon", "tue", "wed", "thu", "fri", "sat", "sun",
                           "mo", "di", "mi", "do", "fr", "sa", "so"]

            for weekday in weekdays {
                if lowercased.hasPrefix(weekday) || lowercased.contains(", \(weekday)") {
                    return true
                }
            }

            // Valid month names
            let months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec",
                         "januar", "februar", "märz", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "dezember"]

            for month in months {
                if lowercased.contains(month) {
                    return true
                }
            }

            // Check for valid numeric date patterns (dd.MM, dd/MM, etc.)
            let numericDatePattern = #"^([0-9]{1,2})[./-]([0-9]{1,2})"#
            if let regex = try? NSRegularExpression(pattern: numericDatePattern),
               let numMatch = regex.firstMatch(in: matchedText, range: NSRange(matchedText.startIndex..., in: matchedText)) {

                // Extract day and month
                if let dayRange = Range(numMatch.range(at: 1), in: matchedText),
                   let monthRange = Range(numMatch.range(at: 2), in: matchedText),
                   let day = Int(matchedText[dayRange]),
                   let month = Int(matchedText[monthRange]) {

                    // Valid date: day 1-31, month 1-12
                    if day >= 1 && day <= 31 && month >= 1 && month <= 12 {
                        return true
                    }
                }
            }
        }

        return false
    }

    // MARK: - Center Crop and Zoom
    /// Crop to center region and zoom in (mimics "zoom 3x on center" in Preview)
    /// - Parameters:
    ///   - cgImage: Source image
    ///   - cropRatio: Ratio of image to keep (0.6 = keep center 60%)
    ///   - zoomFactor: How much to scale up the cropped region (3.0 = 3x zoom)
    /// - Returns: Cropped and zoomed image, or nil if operation fails
    private func centerCropAndZoom(_ cgImage: CGImage, cropRatio: Double, zoomFactor: Double) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height

        // Calculate crop dimensions (center region)
        let cropWidth = Int(Double(width) * cropRatio)
        let cropHeight = Int(Double(height) * cropRatio)
        let cropX = (width - cropWidth) / 2
        let cropY = (height - cropHeight) / 2

        // Crop to center region
        guard let croppedImage = cgImage.cropping(to: CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)) else {
            return nil
        }

        // Zoom (scale up) the cropped region
        let zoomedWidth = Int(Double(cropWidth) * zoomFactor)
        let zoomedHeight = Int(Double(cropHeight) * zoomFactor)

        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = cgImage.bitmapInfo.rawValue

        guard let context = CGContext(
            data: nil,
            width: zoomedWidth,
            height: zoomedHeight,
            bitsPerComponent: croppedImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(croppedImage, in: CGRect(x: 0, y: 0, width: zoomedWidth, height: zoomedHeight))

        return context.makeImage()
    }

    // MARK: - Image Upscaling
    private func upscaleIfNeeded(_ cgImage: CGImage) -> CGImage {
        let width = cgImage.width
        let height = cgImage.height
        let minDimension = min(width, height)

        // If the smallest dimension is less than 1500px, upscale
        // This ensures text is large enough for Vision to detect accurately
        let targetMinDimension = 1500.0

        if Double(minDimension) >= targetMinDimension {
            // Already large enough
            return cgImage
        }

        // Calculate scale factor (e.g., 2x or 3x)
        let scaleFactor = targetMinDimension / Double(minDimension)

        // Create upscaled image
        let newWidth = Int(Double(width) * scaleFactor)
        let newHeight = Int(Double(height) * scaleFactor)

        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = cgImage.bitmapInfo.rawValue

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            // If upscaling fails, return original
            return cgImage
        }

        // Use high quality interpolation
        context.interpolationQuality = .high

        // Draw the image scaled up
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let scaledImage = context.makeImage() else {
            // If scaling fails, return original
            return cgImage
        }

        return scaledImage
    }

    // MARK: - OCR Execution
    private func performOCR(on cgImage: CGImage, mode: VNRequestTextRecognitionLevel) async throws -> String {
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

            request.recognitionLevel = mode
            request.usesLanguageCorrection = true

            // Additional settings for better small text recognition
            request.minimumTextHeight = 0.0  // Detect even very small text
            request.recognitionLanguages = ["en-US", "de-DE"]  // English and German

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TextRecognitionError.visionFailed(error.localizedDescription))
            }
        }
    }
}
