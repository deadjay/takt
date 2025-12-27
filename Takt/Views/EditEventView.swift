import SwiftUI

struct EditEventView: View {
    let event: Event
    @Binding var events: [Event]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var date: Date
    @State private var deadline: Date?
    @State private var notes: String
    @State private var hasDeadline: Bool
    
    init(event: Event, events: Binding<[Event]>) {
        self.event = event
        self._events = events
        self._name = State(initialValue: event.name)
        self._date = State(initialValue: event.date)
        self._deadline = State(initialValue: event.deadline)
        self._notes = State(initialValue: event.notes ?? "")
        self._hasDeadline = State(initialValue: event.deadline != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: $name)
                    
                    DatePicker("Event Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: Binding(
                            get: { deadline ?? Date() },
                            set: { deadline = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func saveChanges() {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        
        events[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        events[index].date = date
        events[index].deadline = hasDeadline ? deadline : nil
        events[index].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EditEventView(
        event: Event(
            name: "Team Meeting",
            date: Date(),
            deadline: Date().addingTimeInterval(86400),
            notes: "Weekly team sync"
        ),
        events: .constant([])
    )
}


