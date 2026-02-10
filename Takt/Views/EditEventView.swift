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

    // TODO: 🎨 REDESIGN THIS FORM (refer to EditEventReference.html)
    //
    // The HTML shows:
    //   - Title input: big bold (20pt), silver-base background, 18px rounded corners,
    //     orange focus ring (2px border + 4px glow)
    //   - Labels: monospaced, 11pt, uppercase, muted color, letter-spacing
    //   - Date pickers: side by side in a grid (Deadline Date + Remind Me At)
    //   - Notes textarea: same silver-base bg, 18px corners, min-height 100px
    //   - "Update Event" button: orange, 20px padding, 20px corners, shadow
    //   - "Delete Permanently" button: red text, no bg, monospaced, uppercase
    //
    // Current implementation uses standard Form. You can replace it with
    // a custom VStack layout for the reference look.

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

                    // Date pickers grid
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EVENT DATE")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(TaktTheme.textMuted)
                                .tracking(1)

                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .tint(TaktTheme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DEADLINE")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(TaktTheme.textMuted)
                                .tracking(1)

                            Toggle("", isOn: $hasDeadline)
                                .labelsHidden()
                                .tint(TaktTheme.accent)

                            if hasDeadline {
                                DatePicker("", selection: Binding(
                                    get: { deadline ?? Date() },
                                    set: { deadline = $0 }
                                ), displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .tint(TaktTheme.accent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                    // Save button
                    Button {
                        saveChanges()
                    } label: {
                        Text("UPDATE EVENT")
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
