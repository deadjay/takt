//
//  UpdateEventUseCase.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

protocol UpdateEventUseCaseProtocol {
    func execute(_ event: Event) async throws
}

final class UpdateEventUseCase: UpdateEventUseCaseProtocol {
    private let repository: EventRepositoryProtocol

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ event: Event) async throws {
        try await repository.updateEvent(event)
    }
}
