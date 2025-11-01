import Foundation

@MainActor
class EventStorageService: ObservableObject {
    @Published var events: [Event] = []
    
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "SavedEvents"
    
    init() {
        loadEvents()
    }
    
    func addEvent(_ event: Event) {
        events.append(event)
        saveEvents()
    }
    
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        }
    }
    
    func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        saveEvents()
    }
    
    func deleteEvents(at offsets: IndexSet) {
        let eventsToDelete = offsets.map { events[$0] }
        events.removeAll { event in
            eventsToDelete.contains { $0.id == event.id }
        }
        saveEvents()
    }
    
    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: eventsKey)
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    private func loadEvents() {
        guard let data = userDefaults.data(forKey: eventsKey) else { return }
        
        do {
            events = try JSONDecoder().decode([Event].self, from: data)
        } catch {
            print("Failed to load events: \(error)")
            events = []
        }
    }
    
    func clearAllEvents() {
        events.removeAll()
        userDefaults.removeObject(forKey: eventsKey)
    }
    
    // MARK: - Event Statistics
    
    var totalEvents: Int {
        events.count
    }
    
    var completedEvents: Int {
        events.filter { $0.isCompleted }.count
    }
    
    var pendingEvents: Int {
        events.filter { !$0.isCompleted }.count
    }
    
    var overdueEvents: Int {
        events.filter { $0.isOverdue }.count
    }
    
    var upcomingEvents: Int {
        let now = Date()
        return events.filter { $0.date > now && !$0.isCompleted }.count
    }
    
    // MARK: - Event Filtering
    
    func eventsForDate(_ date: Date) -> [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    func eventsForDateRange(from startDate: Date, to endDate: Date) -> [Event] {
        return events.filter { event in
            event.date >= startDate && event.date <= endDate
        }
    }
    
    func eventsWithDeadline() -> [Event] {
        return events.filter { $0.deadline != nil }
    }
    
    func searchEvents(query: String) -> [Event] {
        guard !query.isEmpty else { return events }
        
        return events.filter { event in
            event.name.localizedCaseInsensitiveContains(query) ||
            (event.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}

// MARK: - Event Export/Import
extension EventStorageService {
    func exportEvents() -> Data? {
        do {
            return try JSONEncoder().encode(events)
        } catch {
            print("Failed to export events: \(error)")
            return nil
        }
    }
    
    func importEvents(from data: Data) -> Bool {
        do {
            let importedEvents = try JSONDecoder().decode([Event].self, from: data)
            events.append(contentsOf: importedEvents)
            saveEvents()
            return true
        } catch {
            print("Failed to import events: \(error)")
            return false
        }
    }
}
