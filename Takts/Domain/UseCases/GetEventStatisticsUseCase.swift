//
//  GetEventStatisticsUseCase.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

struct EventStatistics {
    let totalEvents: Int
    let completedEvents: Int
    let pendingEvents: Int
    let overdueEvents: Int
    let upcomingEvents: Int
}

protocol GetEventStatisticsUseCaseProtocol {
    func execute() async throws -> EventStatistics
}

final class GetEventStatisticsUseCase: GetEventStatisticsUseCaseProtocol {
    private let repository: EventRepositoryProtocol

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> EventStatistics {
        let events = try await repository.getEvents()
        let now = Date()

        let totalEvents = events.count
        let completedEvents = events.filter { $0.isCompleted }.count
        let pendingEvents = events.filter { !$0.isCompleted }.count
        let overdueEvents = events.filter { $0.isOverdue }.count
        let upcomingEvents = events.filter { $0.date > now && !$0.isCompleted }.count

        return EventStatistics(
            totalEvents: totalEvents,
            completedEvents: completedEvents,
            pendingEvents: pendingEvents,
            overdueEvents: overdueEvents,
            upcomingEvents: upcomingEvents
        )
    }
}
