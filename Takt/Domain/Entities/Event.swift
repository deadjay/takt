import Foundation

enum ReminderOffset: String, Codable, CaseIterable, Identifiable, Equatable {
    case fifteenMinutes = "15min"
    case oneHour = "1h"
    case oneDay = "1d"
    case twoDays = "2d"
    case oneWeek = "1w"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 min before"
        case .oneHour: return "1 hour before"
        case .oneDay: return "1 day before"
        case .twoDays: return "2 days before"
        case .oneWeek: return "1 week before"
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .oneHour: return 60 * 60
        case .oneDay: return 24 * 60 * 60
        case .twoDays: return 2 * 24 * 60 * 60
        case .oneWeek: return 7 * 24 * 60 * 60
        }
    }

}

struct Event: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var deadline: Date?
    var notes: String?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var sourceImageData: Data?
    var titleCandidates: [String]?
    var reminders: [ReminderOffset] = []

    public init(name: String, date: Date, deadline: Date? = nil, notes: String? = nil, sourceImageData: Data? = nil, titleCandidates: [String]? = nil, reminders: [ReminderOffset] = []) {
        self.name = name
        self.date = date
        self.deadline = deadline
        self.notes = notes
        self.sourceImageData = sourceImageData
        self.titleCandidates = titleCandidates
        self.reminders = reminders
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        sourceImageData = try container.decodeIfPresent(Data.self, forKey: .sourceImageData)
        titleCandidates = try container.decodeIfPresent([String].self, forKey: .titleCandidates)
        reminders = try container.decodeIfPresent([ReminderOffset].self, forKey: .reminders) ?? []
    }
}

extension Event {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDeadline: String? {
        guard let deadline = deadline else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: deadline)
    }
    
    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return deadline < Date() && !isCompleted
    }

    /// Returns e.g. "4 Days Left", "Today", or "Overdue" for deadline events
    var daysLeftLabel: String? {
        guard let deadline = deadline, !isCompleted else { return nil }
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: deadline)
        let days = calendar.dateComponents([.day], from: now, to: target).day ?? 0

        if days < 0 { return "Overdue" }
        if days == 0 { return "Today" }
        if days == 1 { return "1 Day Left" }
        return "\(days) Days Left"
    }

    /// Short uppercase date string e.g. "FEB 14"
    var shortDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date).uppercased()
    }

    /// Short time string e.g. "14:30" or "9:00 AM", nil if time is the default 09:00
    var shortTimeLabel: String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0

        // Hide if it's the default 9:00 (parser sets this when no time was found)
        if hour == 9 && minute == 0 { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
