import Foundation

struct Event: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var date: Date
    var deadline: Date?
    var notes: String?
    var isCompleted: Bool = false
    var createdAt: Date = Date()

    init(name: String, date: Date, deadline: Date? = nil, notes: String? = nil) {
        self.name = name
        self.date = date
        self.deadline = deadline
        self.notes = notes
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
}
