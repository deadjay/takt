//
//  EventConfirmationCard.swift
//  Takt
//
//  Created by Artem Alekseev on 27.12.25.
//

import SwiftUI

/// Displays a single extracted event for confirmation with Save/Skip/Cancel options.
/// Redesigned to match AddEventReference.html style.
struct EventConfirmationView: View {

    // MARK: - Public Properties

    @Bindable var viewModel: ScanViewModel

    // MARK: - Body

    // TODO: 🎨 STYLE TWEAKS YOU CAN DO (refer to AddEventReference.html)
    //
    //   - Title input: try font size 32pt, weight .black, letter-spacing -1px
    //   - Add an "etched line" under focused fields (orange gradient, 40px wide)
    //   - Date values could use monospaced orange font like the HTML reference
    //   - The "SAVE EVENT" button has a pulse glow animation in the HTML
    //   - Status badge top-right: "Extracted X Dates" in orange pill

    var body: some View {
        VStack(spacing: 0) {
            // Counter badge
            if !viewModel.eventCounter.isEmpty {
                HStack {
                    Spacer()
                    Text(viewModel.eventCounter.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(TaktTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TaktTheme.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(TaktTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.bottom, 16)
            }

            if let event = viewModel.displayEvent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Source image miniature
                        if let imageData = viewModel.selectedImageData,
                           let uiImage = UIImage(data: imageData) {
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
                                    Text("Scanned input")
                                        .font(.system(size: 13))
                                        .foregroundColor(TaktTheme.textSecondary)
                                }

                                Spacer()
                            }
                        }

                        // Event Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EVENT TITLE")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(TaktTheme.textMuted)
                                .tracking(2)

                            TextField("Untitled Event", text: Binding(
                                get: { viewModel.displayEvent?.name ?? "" },
                                set: {
                                    viewModel.ensureDraft()
                                    viewModel.currentDraft?.name = $0
                                }
                            ))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(TaktTheme.textPrimary)
                            .padding(.vertical, 12)
                            .overlay(
                                Rectangle()
                                    .fill(TaktTheme.cardBorder)
                                    .frame(height: 1),
                                alignment: .bottom
                            )
                        }

                        // Date fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EVENT DATE")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(TaktTheme.textMuted)
                                .tracking(2)

                            DatePicker("", selection: Binding(
                                get: { viewModel.displayEvent?.date ?? Date() },
                                set: {
                                    viewModel.ensureDraft()
                                    viewModel.currentDraft?.date = $0
                                }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(TaktTheme.accent)
                            .padding(.vertical, 8)
                            .overlay(
                                Rectangle()
                                    .fill(TaktTheme.cardBorder)
                                    .frame(height: 1),
                                alignment: .bottom
                            )
                        }

                        // Deadline
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("DEADLINE")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(TaktTheme.textMuted)
                                    .tracking(2)

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { viewModel.displayEvent?.deadline != nil },
                                    set: { hasDeadline in
                                        let eventDate = viewModel.displayEvent?.date ?? Date()
                                        viewModel.ensureDraft()
                                        viewModel.currentDraft?.deadline = hasDeadline ? eventDate : nil
                                    }))
                                .labelsHidden()
                                .tint(TaktTheme.accent)
                            }

                            // Always render DatePicker to avoid format flicker on appear
                            DatePicker("", selection: Binding(
                                get: { viewModel.displayEvent?.deadline ?? viewModel.displayEvent?.date ?? Date() },
                                set: {
                                    viewModel.ensureDraft()
                                    viewModel.currentDraft?.deadline = $0
                                })
                            , displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(TaktTheme.accent)
                            .padding(.vertical, 8)
                            .overlay(
                                Rectangle()
                                    .fill(TaktTheme.cardBorder)
                                    .frame(height: 1),
                                alignment: .bottom
                            )
                            .frame(height: viewModel.displayEvent?.deadline != nil ? nil : 0)
                            .opacity(viewModel.displayEvent?.deadline != nil ? 1 : 0)
                            .clipped()
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(TaktTheme.textMuted)
                                .tracking(2)

                            TextField("Add notes from scan...", text: Binding(
                                get: { viewModel.displayEvent?.notes ?? "" },
                                set: {
                                    viewModel.ensureDraft()
                                    viewModel.currentDraft?.notes = $0.isEmpty ? nil : $0
                                }
                            ), axis: .vertical)
                            .font(.system(size: 16))
                            .foregroundColor(TaktTheme.textPrimary)
                            .lineLimit(3...)
                            .lineSpacing(4)
                            .padding(.vertical, 8)
                            .overlay(
                                Rectangle()
                                    .fill(TaktTheme.cardBorder)
                                    .frame(height: 1),
                                alignment: .bottom
                            )
                        }
                    }
                    .padding(.horizontal, TaktTheme.contentPadding)
                    .padding(.bottom, 24)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    // Save button
                    Button {
                        Task {
                            viewModel.ensureDraft()
                            await viewModel.saveCurrentEvent()
                        }
                    } label: {
                        Text("SAVE EVENT")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(TaktTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: TaktTheme.accent.opacity(0.3), radius: 15, y: 5)
                    }

                    // Skip + Cancel row
                    HStack(spacing: 12) {
                        Button {
                            viewModel.skipCurrentEvent()
                        } label: {
                            Text("SKIP")
                                .font(.system(size: 14, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(TaktTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(TaktTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(TaktTheme.cardBorder, lineWidth: 1)
                                )
                        }

                        Button {
                            viewModel.cancelAll()
                        } label: {
                            Text("CANCEL")
                                .font(.system(size: 14, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.red.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(TaktTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [TaktTheme.appBackground.opacity(0), TaktTheme.appBackground],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.3)
                    )
                )
            }
        }
        .padding(.top, 24)
    }
}
