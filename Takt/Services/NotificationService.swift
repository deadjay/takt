import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleReminders(for event: Event) async
    func cancelReminders(for eventId: UUID)
}

final class NotificationService: NotificationServiceProtocol {

    private let center = UNUserNotificationCenter.current()

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedule all reminders for an event. Cancels existing ones first.
    func scheduleReminders(for event: Event) async {
        cancelReminders(for: event.id)

        guard !event.reminders.isEmpty else { return }

        let referenceDate = event.deadline ?? event.date
        let isDeadline = event.deadline != nil

        for reminder in event.reminders {
            let fireDate: Date
            let body: String
            let identifier: String

            switch reminder {
            case .preset(let offset):
                fireDate = referenceDate.addingTimeInterval(-offset.timeInterval)
                body = isDeadline ? deadlineBody(for: offset) : notificationBody(for: offset)
                identifier = "\(event.id.uuidString)-\(offset.rawValue)"

            case .custom(let date):
                fireDate = date
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                body = "Custom reminder: \(formatter.string(from: date))"
                identifier = "\(event.id.uuidString)-custom-\(Int(date.timeIntervalSince1970))"
            }

            guard fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = event.name
            content.body = body
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                print("Failed to schedule notification \(identifier): \(error)")
            }
        }
    }

    /// Cancel all reminders for an event.
    func cancelReminders(for eventId: UUID) {
        let prefix = eventId.uuidString

        // Cancel all known preset identifiers immediately
        let presetIds = ReminderOffset.allCases.map { "\(prefix)-\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: presetIds)

        // Also cancel any custom identifiers by querying pending requests
        center.getPendingNotificationRequests { requests in
            let customIds = requests
                .filter { $0.identifier.hasPrefix("\(prefix)-custom") }
                .map { $0.identifier }
            if !customIds.isEmpty {
                self.center.removePendingNotificationRequests(withIdentifiers: customIds)
            }
        }
    }

    // MARK: - Private

    private func notificationBody(for offset: ReminderOffset) -> String {
        switch offset {
        case .fifteenMinutes: return "Starting in 15 minutes"
        case .oneHour: return "Starting in 1 hour"
        case .twelveHours: return "Starting in 12 hours"
        case .oneDay: return "Starting in 1 day"
        case .twoDays: return "Starting in 2 days"
        case .oneWeek: return "Starting in 1 week"
        }
    }

    private func deadlineBody(for offset: ReminderOffset) -> String {
        switch offset {
        case .fifteenMinutes: return "Deadline in 15 minutes"
        case .oneHour: return "Deadline in 1 hour"
        case .twelveHours: return "Deadline in 12 hours"
        case .oneDay: return "Deadline in 1 day"
        case .twoDays: return "Deadline in 2 days"
        case .oneWeek: return "Deadline in 1 week"
        }
    }
}
