import SwiftUI

struct CalendarView: View {
    @Binding var events: [Event]
    @Binding var showCalendar: Bool
    @State private var selectedDate = Date()
    @State private var selectedEvent: Event?

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
                // Month header (with list button top-right)
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(TaktTheme.accent)
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(TaktTheme.accent)
                    }
                }
                .padding()
                
                // Days of week header
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                    ForEach(Array(daysInMonth().enumerated()), id: \.offset) { index, date in
                        if let date = date {
                            DayCell(
                                date: date,
                                events: eventsForDate(date),
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        } else {
                            Color.clear
                                .frame(height: 50)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Events for selected date
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Events for \(formattedSelectedDate)")
                            .font(.headline)
                        Spacer()
                        Text("\(eventsForDate(selectedDate).count) events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if eventsForDate(selectedDate).isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No events for this date")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(eventsForDate(selectedDate)) { event in
                                    EventRow(event: event)
                                        .onTapGesture {
                                            selectedEvent = event
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .background(TaktTheme.cardBackground)
                
                Spacer()

                // Bottom bar with list-view toggle (same position as EventsListView's calendar button)
                HStack {
                    Spacer()

                    Button {
                        showCalendar = false
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(TaktTheme.textPrimary)
                            .frame(width: 52, height: 52)
                            .background(TaktTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(TaktTheme.cardBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.vertical, 12)
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event, events: $events)
            }
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining cells to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func eventsForDate(_ date: Date) -> [Event] {
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
}

struct DayCell: View {
    let date: Date
    let events: [Event]
    let isSelected: Bool
    let isToday: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : (isSelected ? TaktTheme.accent : .primary))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isToday ? TaktTheme.accent : (isSelected ? TaktTheme.accent.opacity(0.2) : Color.clear))
                )
            
            // Event indicators
            HStack(spacing: 2) {
                ForEach(Array(events.prefix(3)), id: \.id) { _ in
                    Circle()
                        .fill(TaktTheme.accent)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(height: 50)
    }
}

struct EventRow: View {
    let event: Event

    // TODO: 🎨 REDESIGN THIS ROW (refer to EventsListReference.html)
    //
    // Layout: HStack with two sides
    //   LEFT (event-info):
    //     - event.name  → bold, 18pt, single line
    //     - event.notes → 14pt, secondary color, single line (or "No description")
    //   RIGHT (event-meta):
    //     - event.shortDateLabel → monospaced, bold, 14pt, silver background pill
    //     - If deadline exists:
    //       - Small orange dot (8pt circle, TaktTheme.accent)
    //       - event.daysLeftLabel → orange badge, monospaced, 10pt, uppercase
    //
    // Style: No card/shadow. Just a bottom border (Divider or 1px line).
    //        Padding: 24pt vertical, 0 horizontal.
    //        No chevron arrow.
    //
    // Available data:
    //   event.name            → "Design Review"
    //   event.notes           → "Quarterly audit..." (optional)
    //   event.shortDateLabel  → "OCT 24"
    //   event.deadline        → non-nil means it's a deadline event
    //   event.daysLeftLabel   → "4 Days Left" / "Today" / "Overdue" (optional)
    //   event.isOverdue       → true if past deadline

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: name + description
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(TaktTheme.textPrimary)
                    .lineLimit(1)

                Text(event.notes ?? "No description")
                    .font(.system(size: 14))
                    .foregroundColor(TaktTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Right: date badge + deadline
            VStack(alignment: .trailing, spacing: 8) {
                // TODO: Style this as a silver pill badge (monospaced, bold)
                Text(event.shortDateLabel)
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(TaktTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(TaktTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // TODO: Style the deadline badge (orange dot + label)
                if let daysLeft = event.daysLeftLabel {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(TaktTheme.accent)
                            .frame(width: 8, height: 8)

                        Text(daysLeft.uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(TaktTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    CalendarView(events: .constant([
        Event(name: "Team Meeting", date: Date(), deadline: Date().addingTimeInterval(86400)),
        Event(name: "Project Deadline", date: Date().addingTimeInterval(86400), deadline: Date().addingTimeInterval(172800))
    ]), showCalendar: .constant(true))
}


