import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Binding var events: [Event]
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false

    // Editable fields
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

    // TODO: 🎨 STYLE THIS SHEET (refer to EditEventReference.html)
    //
    // Optional enhancements you can add:
    //   - Drag handle (36×5px, silver, centered, rounded) at the top
    //   - Orange accent gradient line at top (6px, 0.3 opacity)
    //   - Orange focus ring on text fields (2px border + 4px glow when editing)
    //   - Sheet corner radius: .presentationCornerRadius(42) if you want

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EVENT TITLE")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(TaktTheme.textMuted)
                            .tracking(1)

                        TextField("What is the event?", text: $name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(TaktTheme.textPrimary)
                            .padding(16)
                            .background(TaktTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(TaktTheme.cardBorder, lineWidth: 1)
                            )
                    }

                    // Event date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EVENT DATE")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(TaktTheme.textMuted)
                            .tracking(1)

                        DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .tint(TaktTheme.accent)
                    }

                    // Deadline toggle + picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("DEADLINE")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(TaktTheme.textMuted)
                                .tracking(1)

                            Spacer()

                            Toggle("", isOn: $hasDeadline)
                                .labelsHidden()
                                .tint(TaktTheme.accent)
                        }

                        if hasDeadline {
                            DatePicker("", selection: Binding(
                                get: { deadline ?? Date() },
                                set: { deadline = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .tint(TaktTheme.accent)
                        }
                    }

                    // Deadline badge (read-only indicator)
                    if hasDeadline, let daysLeft = computeDaysLeft() {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(daysLeft == "Overdue" ? Color.red : TaktTheme.accent)
                                .frame(width: 8, height: 8)

                            Text(daysLeft.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(daysLeft == "Overdue" ? .red : TaktTheme.accent)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(TaktTheme.textMuted)
                            .tracking(1)

                        TextEditor(text: $notes)
                            .font(.system(size: 16))
                            .foregroundColor(TaktTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 120)
                            .padding(16)
                            .background(TaktTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(TaktTheme.cardBorder, lineWidth: 1)
                            )
                    }

                    Spacer(minLength: 20)

                    // Action buttons
                    VStack(spacing: 12) {
                        // Save button
                        Button {
                            saveChanges()
                        } label: {
                            Text("SAVE EVENT")
                                .font(.system(size: 16, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(TaktTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: TaktTheme.accent.opacity(0.3), radius: 10, y: 5)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                        // Delete button
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Text("DELETE PERMANENTLY")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .tracking(0.5)
                                .foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                }
                .padding(TaktTheme.contentPadding)
            }
            .background(TaktTheme.appBackground)
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(TaktTheme.textMuted),
                trailing: Button("Save") {
                    saveChanges()
                }
                .foregroundColor(TaktTheme.accent)
                .fontWeight(.semibold)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
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

    // MARK: - Actions

    private func saveChanges() {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }

        events[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        events[index].date = date
        events[index].deadline = hasDeadline ? deadline : nil
        events[index].notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)

        presentationMode.wrappedValue.dismiss()
    }

    private func deleteEvent() {
        events.removeAll { $0.id == event.id }
        presentationMode.wrappedValue.dismiss()
    }

    private func computeDaysLeft() -> String? {
        guard let dl = hasDeadline ? (deadline ?? self.deadline) : nil else { return nil }
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: dl)
        let days = calendar.dateComponents([.day], from: now, to: target).day ?? 0

        if days < 0 { return "Overdue" }
        if days == 0 { return "Today" }
        if days == 1 { return "1 Day Left" }
        return "\(days) Days Left"
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
