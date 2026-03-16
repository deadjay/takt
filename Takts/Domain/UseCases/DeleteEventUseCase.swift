//
//  DeleteEventUseCase.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

protocol DeleteEventUseCaseProtocol {
    func execute(_ event: Event) async throws
    func execute(withIds ids: [UUID]) async throws
}

final class DeleteEventUseCase: DeleteEventUseCaseProtocol {
    private let repository: EventRepositoryProtocol

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ event: Event) async throws {
        try await repository.deleteEvent(event)
    }

    func execute(withIds ids: [UUID]) async throws {
        try await repository.deleteEvents(withIds: ids)
    }
}
