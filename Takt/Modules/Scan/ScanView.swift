//
//  ScanView.swift
//  Takt
//
//  Created by Artem Alekseev on 27.12.25.
//

import SwiftUI

struct ScanView: View {
    @State private var viewModel: ScanViewModel
    @State private var showError: Bool = false
    @State private var showSuccessCheckmark = false

    init(viewModel: ScanViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Main content
            if viewModel.isProcessing {
                ProcessingView(showProgress: viewModel.showProgressIndicator)
            } else if viewModel.hasExtractedEvents {
                EventConfirmationView(viewModel: viewModel)
            } else {
                IdleStateView(viewModel: viewModel, showSuccessCheckmark: $showSuccessCheckmark)
            }
        }
        .overlay(alignment: .center) {
            if showSuccessCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .padding(20)
                    .background (
                        Material.thin
                    )
                    .cornerRadius(16)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.hasError) { _, hasError in
            showError = hasError
        }
        .onChange(of: viewModel.selectedImageData) { oldValue, newValue in
            guard newValue != nil else { return }
            
            withAnimation(.spring(response: 0.3)) {
                showSuccessCheckmark = true
            }

            Task {
                try? await Task.sleep(for: .seconds(1))
                withAnimation(.spring(response: 0.3)) {
                    showSuccessCheckmark = false
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

// MARK: - Idle State (Input Selection)

private struct IdleStateView: View {
    @Bindable var viewModel: ScanViewModel
    @Binding var showSuccessCheckmark: Bool

    var body: some View {
        ZStack {
            // Background
            TaktTheme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Takt.")
                        .font(.system(size: 30, weight: .heavy))
                        .tracking(-1.6)
                        .foregroundColor(TaktTheme.textPrimary)
                        .textCase(.uppercase)

                    Text("Snap a photo, upload an image, or paste text — Takt extracts dates and creates reminders automatically.")
                        .font(.system(size: 13))
                        .foregroundColor(TaktTheme.textSecondary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.top, 16)

                // Two square action cards in a row
                HStack(spacing: 16) {
                    // TODO: You implement ActionCard views here
                    // Camera card (01 / CAPTURE - "Make Photo")
                    ImageInputButton(
                        icon: "camera.fill",
                        label: "01 / CAPTURE",
                        title: "Make Photo",
                        imageData: $viewModel.selectedImageData,
                        sourceType: .camera
                    )

                    // Upload card (02 / IMPORT - "Attach Image")
                    ImageInputButton(
                        icon: "photo.fill",
                        label: "02 / IMPORT",
                        title: "Attach Image",
                        imageData: $viewModel.selectedImageData,
                        sourceType: .photoLibrary
                    )
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.top, 24)

                // Text input card
                TextInputField(
                    text: $viewModel.inputText,
                    onPaste: {
                        viewModel.pasteFromClipboard()
                    }
                )
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.top, 16)

                Spacer()

                // Quick Tips
                VStack(alignment: .leading, spacing: 6) {
                    Text("QUICK TIPS")
                        .font(TaktTheme.cardLabelFont)
                        .foregroundColor(TaktTheme.textMuted)
                        .padding(.bottom, 2)

                    TipRow(text: "Works with tickets, receipts, food labels, subscriptions")
                    TipRow(text: "Detects dates, times, and deadlines automatically")
                    TipRow(text: "Everything stays on your device — fully offline")
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.bottom, 20)

                // Magic button - always visible at bottom
                Button {
                    Task {
                        if viewModel.selectedImageData != nil {
                            await viewModel.processImage()
                        } else {
                            await viewModel.processText()
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("DETECT EVENTS")
                            .font(TaktTheme.magicButtonFont)
                            .tracking(1.8)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: TaktTheme.magicButtonHeight)
                    .background(TaktTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: TaktTheme.magicButtonCornerRadius))
                    .shadow(color: TaktTheme.accent.opacity(0.30), radius: 15, y: 8)
                }
                .disabled(viewModel.selectedImageData == nil && viewModel.inputText.isEmpty)
                .opacity(viewModel.selectedImageData == nil && viewModel.inputText.isEmpty ? 0.5 : 1.0)
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Processing View

private struct ProcessingView: View {
    let showProgress: Bool

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            if showProgress {
                Text("Extracting text...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Components

private struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(TaktTheme.textMuted)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(TaktTheme.textMuted)
        }
    }
}

private struct TextInputField: View {
    @Binding var text: String
    let onPaste: () -> Void

    var body: some View {
        // TODO: You can restyle this card to match the design!
        // It should look like the action cards but wider (full width, not square)
        // Label: "03 / INPUT", Title area is the text field

        VStack(alignment: .leading, spacing: 8) {
            Text("03 / INPUT")
                .font(TaktTheme.cardLabelFont)
                .foregroundColor(TaktTheme.textMuted)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                TextField("Paste or type text...", text: $text)
                    .textFieldStyle(.plain)
                    .font(TaktTheme.cardTitleFont)
                    .foregroundColor(TaktTheme.textPrimary)

                Button {
                    onPaste()
                } label: {
                    Text("Paste")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(TaktTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(TaktTheme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TaktTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TaktTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: TaktTheme.cardCornerRadius)
                .stroke(TaktTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ScanView(
        viewModel: ScanViewModel(
            textRecognitionService: DIContainer.shared.textRecognitionService,
            textEventParserService: DIContainer.shared.textEventParserService,
            addEventUseCase: DIContainer.shared.addEventUseCase
        )
    )
}

#Preview {
    IdleStateView(viewModel: ScanViewModel(
        textRecognitionService: DIContainer.shared.textRecognitionService,
        textEventParserService: DIContainer.shared.textEventParserService,
        addEventUseCase: DIContainer.shared.addEventUseCase
    ), showSuccessCheckmark: .constant(true))
}
