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
    private let updateEventUseCase: UpdateEventUseCaseProtocol
    private let deleteEventUseCase: DeleteEventUseCaseProtocol
    private let searchEventsUseCase: SearchEventsUseCaseProtocol
    private let notificationService: NotificationServiceProtocol

    // MARK: - Init
    init(
        getEventsUseCase: GetEventsUseCaseProtocol,
        updateEventUseCase: UpdateEventUseCaseProtocol,
        deleteEventUseCase: DeleteEventUseCaseProtocol,
        searchEventsUseCase: SearchEventsUseCaseProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.getEventsUseCase = getEventsUseCase
        self.updateEventUseCase = updateEventUseCase
        self.deleteEventUseCase = deleteEventUseCase
        self.searchEventsUseCase = searchEventsUseCase
        self.notificationService = notificationService
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

    /// Events grouped by calendar day, sorted chronologically.
    /// Each group has a date (start of day) and its events.
    var dayGroups: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.date)
        }
        return grouped
            .map { DayGroup(date: $0.key, events: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.date < $1.date }
    }

    /// Day groups before today
    var pastDayGroups: [DayGroup] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return dayGroups.filter { $0.date < startOfToday }
    }

    /// Day groups from today onward
    var upcomingDayGroups: [DayGroup] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return dayGroups.filter { $0.date >= startOfToday }
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
    func updateEvent(_ event: Event) async {
        do {
            try await updateEventUseCase.execute(event)
            await notificationService.scheduleReminders(for: event)
            await loadEvents()
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
            for id in ids {
                notificationService.cancelReminders(for: id)
            }
            try await deleteEventUseCase.execute(withIds: ids)
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Weekday header label for a date: "MONDAY, MAR 09"
    func dayHeaderLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return todayLabel }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM dd"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Supporting Types

struct DayGroup: Identifiable {
    let date: Date
    let events: [Event]
    var id: Date { date }
}
