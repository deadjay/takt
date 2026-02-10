import Foundation

struct Event: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var deadline: Date?
    var notes: String?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var sourceImageData: Data?

    public init(name: String, date: Date, deadline: Date? = nil, notes: String? = nil, sourceImageData: Data? = nil) {
        self.name = name
        self.date = date
        self.deadline = deadline
        self.notes = notes
        self.sourceImageData = sourceImageData
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
}
