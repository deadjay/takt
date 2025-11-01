import SwiftUI

struct CalendarView: View {
    @Binding var events: [Event]
    @State private var selectedDate = Date()
    @State private var showingEventDetail = false
    @State private var selectedEvent: Event?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month header
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
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
                    ForEach(daysInMonth(), id: \.self) { date in
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
                                            showingEventDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .background(Color.gray.opacity(0.05))
                
                Spacer()
            }
            .navigationTitle("Calendar")
            .sheet(isPresented: $showingEventDetail) {
                if let event = selectedEvent {
                    EventDetailView(event: event, events: $events)
                }
            }
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
                .foregroundColor(isToday ? .white : (isSelected ? .blue : .primary))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isToday ? Color.blue : (isSelected ? Color.blue.opacity(0.2) : Color.clear))
                )
            
            // Event indicators
            HStack(spacing: 2) {
                ForEach(Array(events.prefix(3)), id: \.id) { _ in
                    Circle()
                        .fill(Color.blue)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(event.formattedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let deadline = event.formattedDeadline {
                        Label(deadline, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if event.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    CalendarView(events: .constant([
        Event(name: "Team Meeting", date: Date(), deadline: Date().addingTimeInterval(86400)),
        Event(name: "Project Deadline", date: Date().addingTimeInterval(86400), deadline: Date().addingTimeInterval(172800))
    ]))
}
