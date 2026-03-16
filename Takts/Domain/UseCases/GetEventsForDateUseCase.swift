//
//  GetEventsForDateUseCase.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

protocol GetEventsForDateUseCaseProtocol {
    func execute(date: Date) async throws -> [Event]
    func execute(from startDate: Date, to endDate: Date) async throws -> [Event]
}

final class GetEventsForDateUseCase: GetEventsForDateUseCaseProtocol {
    private let repository: EventRepositoryProtocol

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute(date: Date) async throws -> [Event] {
        try await repository.eventsForDate(date)
    }

    func execute(from startDate: Date, to endDate: Date) async throws -> [Event] {
        try await repository.eventsForDateRange(from: startDate, to: endDate)
    }
}
