//
//  SearchEventsUseCase.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

protocol SearchEventsUseCaseProtocol {
    func execute(query: String) async throws -> [Event]
}

final class SearchEventsUseCase: SearchEventsUseCaseProtocol {
    private let repository: EventRepositoryProtocol

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String) async throws -> [Event] {
        try await repository.searchEvents(query: query)
    }
}
