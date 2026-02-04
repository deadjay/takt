//
//  EventDraftEditView.swift
//  Takt
//
//  Created by Artem Alekseev on 03.02.26.
//

import SwiftUI

struct EventDraftEditView: View {
    @Binding var draft: Event
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var date: Date
    @State private var deadline: Date?
    @State private var notes: String
    @State private var hasDeadline: Bool
    
    init(draft: Binding<Event>) {
        self._draft = draft
        self._name = State(initialValue: draft.wrappedValue.name)
        self._date = State(initialValue: draft.wrappedValue.date)
        self._deadline = State(initialValue: draft.wrappedValue.deadline)
        self._notes = State(initialValue: draft.wrappedValue.notes ?? "")
        self._hasDeadline = State(initialValue: draft.wrappedValue.deadline != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: $name)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
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
            }
            .navigationTitle("Edit Event")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            },
                                trailing: Button("Save") {
                saveChanges()
            })
        }
    }
    
    private func saveChanges() {
        draft.name = name
        draft.date = date
        draft.deadline = hasDeadline ? deadline : nil
        draft.notes = notes.isEmpty ? nil : notes
        
        presentationMode.wrappedValue.dismiss()
        
    }
}


#Preview {
    EventDraftEditView(draft: .constant(Event(
        name: "Team Meeting",
        date: Date(),
        deadline: Date().addingTimeInterval(86400),
        notes: "Weekly team sync"
    )))
}
