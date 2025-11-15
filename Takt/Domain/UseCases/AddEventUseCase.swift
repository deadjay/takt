//
//  AddEventUseCase.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

protocol AddEventUseCaseProtocol {
    func execute(_ event: Event) async throws
}

final class AddEventUseCase: AddEventUseCaseProtocol {
    private let repository: EventRepositoryProtocol

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ event: Event) async throws {
        try await repository.addEvent(event)
    }
}
