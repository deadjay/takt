import SwiftUI

struct AddEventView: View {
    @Binding var events: [Event]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var date = Date()
    @State private var deadline: Date?
    @State private var notes = ""
    @State private var hasDeadline = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: $name)
                    
                    DatePicker("Event Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Set Deadline", isOn: $hasDeadline)
                        .onChange(of: hasDeadline) { _, isOn in
                            if isOn && deadline == nil {
                                deadline = date
                            }
                        }

                    if hasDeadline {
                        DatePicker("Deadline", selection: Binding(
                            get: { deadline ?? date },
                            set: { deadline = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Add Event") {
                        addEvent()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(TaktTheme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    addEvent()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func addEvent() {
        let newEvent = Event(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            deadline: hasDeadline ? deadline : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        events.append(newEvent)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddEventView(events: .constant([]))
}


