import Vision
import UIKit
import Foundation

protocol TextRecognitionServiceProtocol {
    func recognizeText(fromImageData data: Data) async throws -> String
}
