import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Binding var events: [Event]
    var onSave: ((Event) -> Void)? = nil
    var onDelete: ((UUID) -> Void)? = nil
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var showingImagePreview = false

    // Editable fields
    @State private var name: String
    @State private var date: Date
    @State private var deadline: Date?
    @State private var notes: String
    @State private var hasDeadline: Bool
    @State private var reminders: [Reminder]

    init(event: Event, events: Binding<[Event]>, onSave: ((Event) -> Void)? = nil, onDelete: ((UUID) -> Void)? = nil) {
        self.event = event
        self._events = events
        self.onSave = onSave
        self.onDelete = onDelete
        self._name = State(initialValue: event.name)
        self._date = State(initialValue: event.date)
        self._deadline = State(initialValue: event.deadline)
        self._notes = State(initialValue: event.notes ?? "")
        self._hasDeadline = State(initialValue: event.deadline != nil)
        self._reminders = State(initialValue: event.reminders)
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
                    // Source image miniature (tap to preview)
                    if let imageData = event.sourceImageData,
                       let uiImage = UIImage(data: imageData) {
                        Button {
                            showingImagePreview = true
                        } label: {
                            HStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(TaktTheme.cardBorder, lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SOURCE IMAGE")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundColor(TaktTheme.textMuted)
                                        .tracking(1)
                                    Text("Tap to preview")
                                        .font(.system(size: 13))
                                        .foregroundColor(TaktTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(TaktTheme.textMuted)
                            }
                        }
                        .buttonStyle(.plain)
                        .fullScreenCover(isPresented: $showingImagePreview) {
                            ImagePreviewView(imageData: imageData)
                        }
                    }

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
                            .datePickerStyle(.compact)
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
                                .onChange(of: hasDeadline) { _, isOn in
                                    if isOn && deadline == nil {
                                        deadline = date
                                    }
                                }
                        }

                        DatePicker("", selection: Binding(
                            get: { deadline ?? date },
                            set: { deadline = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(TaktTheme.accent)
                        .frame(height: hasDeadline ? nil : 0)
                        .opacity(hasDeadline ? 1 : 0)
                        .clipped()
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

                    // Reminders
                    remindersSection

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

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REMINDERS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(TaktTheme.textMuted)
                .tracking(1)

            ForEach(Array(reminders.enumerated()), id: \.offset) { (index: Int, reminder: Reminder) in
                reminderRow(index: index, reminder: reminder)
            }

            if reminders.count < 3 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        let usedPresets = Set(reminders.compactMap {
                            if case .preset(let o) = $0 { return o } else { return nil }
                        })
                        if let next = ReminderOffset.allCases.first(where: { !usedPresets.contains($0) }) {
                            reminders.append(.preset(next))
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(TaktTheme.accent)

                        Text("Add Reminder")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(TaktTheme.accent)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        events[index].name = trimmedName
        events[index].date = date
        events[index].deadline = hasDeadline ? deadline : nil
        events[index].notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        events[index].reminders = reminders

        onSave?(events[index])
        presentationMode.wrappedValue.dismiss()
    }

    private func deleteEvent() {
        let id = event.id
        onDelete?(id)
        events.removeAll { $0.id == id }
        presentationMode.wrappedValue.dismiss()
    }

    @ViewBuilder
    private func reminderRow(index: Int, reminder: Reminder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 14))
                .foregroundColor(TaktTheme.accent)
                .frame(width: 20)

            switch reminder {
            case .preset(let offset):
                Menu {
                    ForEach(availableOffsets(for: index)) { o in
                        Button(o.displayName) {
                            reminders[index] = .preset(o)
                        }
                    }
                    Divider()
                    Button("Custom...") {
                        reminders[index] = .custom(date)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(offset.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(TaktTheme.textPrimary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(TaktTheme.textMuted)
                    }
                }

            case .custom(let reminderDate):
                DatePicker("", selection: Binding(
                    get: { reminderDate },
                    set: { reminders[index] = .custom($0) }
                ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(TaktTheme.accent)
            }

            Spacer()

            Button {
                let idx = index
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = reminders.remove(at: idx)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    private func availableOffsets(for index: Int) -> [ReminderOffset] {
        let usedByOthers = Set(reminders.enumerated().compactMap { i, r -> ReminderOffset? in
            guard i != index, case .preset(let o) = r else { return nil }
            return o
        })
        return ReminderOffset.allCases.filter { !usedByOthers.contains($0) }
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
