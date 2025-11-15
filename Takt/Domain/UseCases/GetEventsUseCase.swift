//
//  GetEventsUseCase.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

protocol GetEventsUseCaseProtocol {
    func execute() async throws -> [Event]
}

final class GetEventsUseCase: GetEventsUseCaseProtocol {
    private let repository: EventRepositoryProtocol

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [Event] {
        try await repository.getEvents()
    }
}
