//
//  EventConfirmationCard.swift
//  Takt
//
//  Created by Artem Alekseev on 27.12.25.
//

import SwiftUI

/// Displays a single event for confirmation with Save/Skip/Cancel options
struct EventConfirmationView: View {
    
    // MARK: - Public Properties
    
    @Bindable var viewModel: ScanViewModel
    
    // MARK: - Private Properties
    
    var body: some View {
        VStack(spacing: 24) {
            // Counter (1/3, 2/3, etc.)
            if !viewModel.eventCounter.isEmpty {
                Text(viewModel.eventCounter)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }

            // Event Preview Card
            if let event = viewModel.displayEvent {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.title2)
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Event Found")
                                .font(.headline)
                            Text("Review before saving")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Divider()

                    // Event Details (Editable)
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack(spacing: 12) {
                            
                            Image(systemName: "text.alignleft")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Event name", text: Binding(
                                    get: { viewModel.displayEvent?.name ?? "" },
                                    set: {
                                        viewModel.ensureDraft()
                                        viewModel.currentDraft?.name = $0
                                    }
                                ))
                                .font(.body)
                            }
                        }
                        
                        Divider()
                        
                        //Date
                        
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reminder Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: Binding(
                                    get: { viewModel.displayEvent?.date ?? Date() },
                                    set: {
                                        viewModel.ensureDraft()
                                        viewModel.currentDraft?.date = $0
                                    }
                                ), displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        Divider()
                        
                        // Deadline Toggle + Picker
                        
                        HStack(spacing: 12) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.body)
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Toggle("Set Deadline", isOn: Binding(
                                    get: { viewModel.displayEvent?.deadline != nil },
                                    set: { hasDeadline in
                                        viewModel.ensureDraft()
                                        viewModel.currentDraft?.deadline = hasDeadline ? Date() : nil
                                    }))
                                .font(.body)
                                .tint(.red)
                                
                                if viewModel.displayEvent?.deadline != nil {
                                    DatePicker("", selection: Binding(
                                        get: { viewModel.displayEvent?.deadline ?? Date() },
                                        set: {
                                            viewModel.ensureDraft()
                                            viewModel.currentDraft?.deadline = $0
                                        })
                                               , displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Notes
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "note.text")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Add notes...", text: Binding(
                                    get: { viewModel.displayEvent?.notes ?? "" },
                                    set: {
                                        viewModel.ensureDraft()
                                        viewModel.currentDraft?.notes = $0.isEmpty ? nil : $0 }
                                ), axis: .vertical)
                                .font(.body)
                                .lineLimit(3...)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
                .padding(.horizontal, 20)
            }

            // Action Buttons
            VStack(spacing: 12) {
                // Save Button
                Button {
                    Task {
                        viewModel.ensureDraft()
                        await viewModel.saveCurrentEvent()
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Event")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }

                // Skip / Cancel Row
                HStack(spacing: 12) {
                    // Skip Button
                    Button {
                        viewModel.skipCurrentEvent()
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip")
                        }
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Cancel All Button
                    Button {
                        viewModel.cancelAll()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cancel All")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 40)
    }
}

// MARK: - Detail Row Component

private struct EventDetailRowView: View {
    let icon: String
    let label: String
    let value: String
    var isDeadline: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(isDeadline ? .red : .blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(isDeadline ? .red : .primary)
            }

            Spacer()
        }
    }
}
