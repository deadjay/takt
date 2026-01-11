import Testing
import Foundation
@testable import Takt

/// Tests using REAL images with actual Vision OCR
/// These tests validate the full pipeline with real-world photos
@Suite("Real Image OCR Tests")
struct RealImageOCRTests {

    // MARK: - Helper Methods

    private func loadImageData(named filename: String) throws -> Data {
        // For Swift Testing framework, use Bundle.module or find the test bundle
        let testBundle = Bundle(for: TextEventParserTests.self)
        guard let url = testBundle.url(forResource: filename, withExtension: nil, subdirectory: "TestImages") else {
            throw TestError.imageNotFound(filename)
        }
        return try Data(contentsOf: url)
    }

    private func makeTextRecognitionService() -> TextRecognitionServiceProtocol {
        return DefaultTextRecognitionService()
    }

    private func makeTextEventParser() -> TextEventParserServiceProtocol {
        return TextEventParser()
    }

    enum TestError: Error {
        case imageNotFound(String)
    }

    // Rest of the code remains the same
}
