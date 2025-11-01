import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Binding var events: [Event]
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Event header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .lineLimit(nil)
                        
                        HStack {
                            Label(event.formattedDate, systemImage: "calendar")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            if event.isOverdue {
                                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Event details
                    VStack(alignment: .leading, spacing: 16) {
                        if let deadline = event.deadline {
                            DetailRow(
                                icon: "clock",
                                title: "Deadline",
                                value: formatDate(deadline),
                                color: event.isOverdue ? .red : .orange
                            )
                        }
                        
                        DetailRow(
                            icon: "note.text",
                            title: "Notes",
                            value: event.notes ?? "No notes",
                            color: .secondary
                        )
                        
                        DetailRow(
                            icon: "calendar.badge.plus",
                            title: "Created",
                            value: formatDate(event.createdAt),
                            color: .secondary
                        )
                        
                        DetailRow(
                            icon: "checkmark.circle",
                            title: "Status",
                            value: event.isCompleted ? "Completed" : "Pending",
                            color: event.isCompleted ? .green : .blue
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            toggleEventCompletion()
                        }) {
                            HStack {
                                Image(systemName: event.isCompleted ? "xmark.circle" : "checkmark.circle")
                                Text(event.isCompleted ? "Mark as Pending" : "Mark as Completed")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(event.isCompleted ? Color.orange : Color.green)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Event")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingEditSheet) {
                EditEventView(event: event, events: $events)
            }
            .alert("Delete Event", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteEvent()
                }
            } message: {
                Text("Are you sure you want to delete '\(event.name)'? This action cannot be undone.")
            }
        }
    }
    
    private func toggleEventCompletion() {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isCompleted.toggle()
        }
    }
    
    private func deleteEvent() {
        events.removeAll { $0.id == event.id }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    EventDetailView(
        event: Event(
            name: "Team Meeting",
            date: Date(),
            deadline: Date().addingTimeInterval(86400),
            notes: "Weekly team sync to discuss project progress and upcoming milestones."
        ),
        events: .constant([])
    )
}
