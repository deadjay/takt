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

        // Simple strategy: Always use full image upscaling
        // NOTE: Future improvement - detect if parser can extract dates,
        // and only then try center crop as fallback
        let processedImage = upscaleIfNeeded(cgImage)
        return try await performOCR(on: processedImage, mode: .accurate)
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
