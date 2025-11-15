//
//  UserDefaultsEventRepository.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation

final class UserDefaultsEventRepository: EventRepositoryProtocol {

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let eventsKey = "SavedEvents"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - CRUD Operations

    func getEvents() async throws -> [Event] {
        guard let data = userDefaults.data(forKey: eventsKey) else {
            return []
        }

        do {
            return try decoder.decode([Event].self, from: data)
        } catch {
            throw RepositoryError.decodingFailed(error)
        }
    }

    func addEvent(_ event: Event) async throws {
        var events = try await getEvents()
        events.append(event)
        try await saveEvents(events)
    }

    func updateEvent(_ event: Event) async throws {
        var events = try await getEvents()

        guard let index = events.firstIndex(where: { $0.id == event.id }) else {
            throw RepositoryError.eventNotFound
        }

        events[index] = event
        try await saveEvents(events)
    }

    func deleteEvent(_ event: Event) async throws {
        var events = try await getEvents()
        events.removeAll { $0.id == event.id }
        try await saveEvents(events)
    }

    func deleteEvents(withIds ids: [UUID]) async throws {
        var events = try await getEvents()
        events.removeAll { ids.contains($0.id) }
        try await saveEvents(events)
    }

    func clearAllEvents() async throws {
        userDefaults.removeObject(forKey: eventsKey)
    }

    // MARK: - Queries

    func eventsForDate(_ date: Date) async throws -> [Event] {
        let events = try await getEvents()
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }

    func eventsForDateRange(from startDate: Date, to endDate: Date) async throws -> [Event] {
        let events = try await getEvents()
        return events.filter { event in
            event.date >= startDate && event.date <= endDate
        }
    }

    func eventsWithDeadline() async throws -> [Event] {
        let events = try await getEvents()
        return events.filter { $0.deadline != nil }
    }

    func searchEvents(query: String) async throws -> [Event] {
        let events = try await getEvents()

        guard !query.isEmpty else {
            return events
        }

        return events.filter { event in
            event.name.localizedCaseInsensitiveContains(query) ||
            (event.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    // MARK: - Import/Export

    func exportEvents() async throws -> Data {
        let events = try await getEvents()

        do {
            return try encoder.encode(events)
        } catch {
            throw RepositoryError.encodingFailed(error)
        }
    }

    func importEvents(from data: Data) async throws {
        let importedEvents: [Event]

        do {
            importedEvents = try decoder.decode([Event].self, from: data)
        } catch {
            throw RepositoryError.decodingFailed(error)
        }

        var events = try await getEvents()
        events.append(contentsOf: importedEvents)
        try await saveEvents(events)
    }

    // MARK: - Private Methods

    private func saveEvents(_ events: [Event]) async throws {
        do {
            let data = try encoder.encode(events)
            userDefaults.set(data, forKey: eventsKey)
        } catch {
            throw RepositoryError.encodingFailed(error)
        }
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case eventNotFound

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .eventNotFound:
            return "Event not found"
        }
    }
}
