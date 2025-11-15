//
//  EventRepositoryProtocol.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

protocol EventRepositoryProtocol {
    // MARK: - CRUD Operations
    func getEvents() async throws -> [Event]
    func addEvent(_ event: Event) async throws
    func updateEvent(_ event: Event) async throws
    func deleteEvent(_ event: Event) async throws
    func deleteEvents(withIds ids: [UUID]) async throws
    func clearAllEvents() async throws

    // MARK: - Queries
    func eventsForDate(_ date: Date) async throws -> [Event]
    func eventsForDateRange(from startDate: Date, to endDate: Date) async throws -> [Event]
    func eventsWithDeadline() async throws -> [Event]
    func searchEvents(query: String) async throws -> [Event]

    // MARK: - Import/Export
    func exportEvents() async throws -> Data
    func importEvents(from data: Data) async throws
}
