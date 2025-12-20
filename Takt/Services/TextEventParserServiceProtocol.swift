//
//  TextEventParserServiceProtocol.swift
//  Takt
//
//  Created by Artem Alekseev on 20.12.25.
//

// Define a publicly accessible Event struct
//public struct PublicEvent: Event {
//    let identifier: String
//    var data: [String: Any]
//}

// MARK: - Protocol for TextEventParser to support DI
protocol TextEventParserServiceProtocol {
    /// Recognizes text from image data and returns the full recognized string.
    func parseEvents(from text: String) throws -> [Event]
}
