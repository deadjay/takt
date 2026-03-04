//
//  EventsListViewModel.swift
//  Takt
//
//  Created by Artem Alekseev on 15.11.25.
//

import Foundation
import Observation

@Observable
final class EventsListViewModel {

    // MARK: - State
    var events: [Event] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var searchText: String = ""

    // MARK: - Dependencies
    private let getEventsUseCase: GetEventsUseCaseProtocol
    private let deleteEventUseCase: DeleteEventUseCaseProtocol
    private let searchEventsUseCase: SearchEventsUseCaseProtocol

    // MARK: - Init
    init(
        getEventsUseCase: GetEventsUseCaseProtocol,
        deleteEventUseCase: DeleteEventUseCaseProtocol,
        searchEventsUseCase: SearchEventsUseCaseProtocol
    ) {
        self.getEventsUseCase = getEventsUseCase
        self.deleteEventUseCase = deleteEventUseCase
        self.searchEventsUseCase = searchEventsUseCase
    }

    // MARK: - Computed Properties
    var filteredEvents: [Event] {
        events.sorted { $0.date < $1.date }
    }

    /// "TODAY, MAR 03" label for the today divider row
    var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return "TODAY, \(formatter.string(from: Date()).uppercased())"
    }

    /// Index in filteredEvents where the Today divider should be inserted
    /// (before the first event that is today or later)
    var todayInsertIndex: Int {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return filteredEvents.firstIndex { $0.date >= startOfToday } ?? filteredEvents.count
    }

    // MARK: - Actions
    @MainActor
    func loadEvents() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            events = try await getEventsUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func searchEvents(query: String) async {
        searchText = query
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            events = try await searchEventsUseCase.execute(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteEvents(withIds ids: [UUID]) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await deleteEventUseCase.execute(withIds: ids)
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
