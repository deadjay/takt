//
//  ScanView.swift
//  Takt
//
//  Created by Artem Alekseev on 27.12.25.
//

import SwiftUI
import UniformTypeIdentifiers

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
                    .transition(.opacity)
            } else if viewModel.hasExtractedEvents {
                EventConfirmationView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                IdleStateView(viewModel: viewModel, showSuccessCheckmark: $showSuccessCheckmark)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasExtractedEvents)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isProcessing)
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
        .onChange(of: viewModel.showSuccessToast) { _, show in
            guard show else { return }
            withAnimation(.spring(response: 0.3)) {
                showSuccessCheckmark = true
            }
            viewModel.showSuccessToast = false
            Task {
                try? await Task.sleep(for: .seconds(1.2))
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
    @State private var showInfo = false

    // Animation tracking
    @State private var scanButtonCenter: CGPoint = .zero
    @State private var attachButtonCenter: CGPoint = .zero
    @State private var detectButtonFrame: CGRect = .zero
    @State private var isAnimatingThumbnail = false
    @State private var thumbnailLanded = false
    @State private var lastInputWasCamera = true
    @State private var isDropTargeted = false

    private var hasImage: Bool { viewModel.selectedImageData != nil }

    var body: some View {
        ZStack {
            TaktTheme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("Takt.")
                            .font(.system(size: 48, weight: .heavy))
                            .tracking(-2.4)
                            .foregroundColor(TaktTheme.textPrimary)
                            .textCase(.uppercase)

                        Spacer()

                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 20))
                                .foregroundColor(TaktTheme.textMuted)
                        }
                    }

                    Text("Snap a photo, upload an image, or paste text — Takt extracts dates and creates reminders automatically.")
                        .font(.system(size: 15))
                        .foregroundColor(TaktTheme.textSecondary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)

                Spacer(minLength: 0)

                // Bottom input area
                VStack(spacing: 10) {
                    // Drag & Drop area
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(TaktTheme.textMuted.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .frame(height: 56)
                            .overlay {
                                VStack(spacing: 2) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(TaktTheme.textMuted)
                                    Text("Drag & Drop")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(TaktTheme.textMuted)
                                }
                            }

                        OrSeparator()
                    }

                    // Scan + Attach (square, side by side)
                    HStack(spacing: 12) {
                        ImageInputButton(
                            icon: "camera.fill",
                            label: "CAPTURE",
                            title: "Scan",
                            imageData: $viewModel.selectedImageData,
                            sourceType: .camera,
                            onTap: { lastInputWasCamera = true }
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    scanButtonCenter = CGPoint(
                                        x: geo.frame(in: .named("idle")).midX,
                                        y: geo.frame(in: .named("idle")).midY
                                    )
                                }
                            }
                        )

                        ImageInputButton(
                            icon: "photo.fill",
                            label: "IMPORT",
                            title: "Attach",
                            imageData: $viewModel.selectedImageData,
                            sourceType: .photoLibrary,
                            onTap: { lastInputWasCamera = false }
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    attachButtonCenter = CGPoint(
                                        x: geo.frame(in: .named("idle")).midX,
                                        y: geo.frame(in: .named("idle")).midY
                                    )
                                }
                            }
                        )
                    }

                    OrSeparator()

                    // Text input (disabled when image attached)
                    TextInputField(
                        text: $viewModel.inputText,
                        isDisabled: hasImage,
                        onPaste: {
                            viewModel.pasteFromClipboard()
                        }
                    )

                    // Detect Events button
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
                    .disabled(!hasImage && viewModel.inputText.isEmpty)
                    .opacity(!hasImage && viewModel.inputText.isEmpty ? 0.5 : 1.0)
                    .overlay(alignment: .leading) {
                        // Static thumbnail on detect button (shown after animation lands)
                        if hasImage && !isAnimatingThumbnail,
                           let imageData = viewModel.selectedImageData,
                           let uiImage = UIImage(data: imageData) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedImageData = nil
                                }
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 2)
                                        .offset(x: 6, y: -6)
                                }
                            }
                            .offset(x: 16)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                detectButtonFrame = geo.frame(in: .named("idle"))
                            }
                        }
                    )
                }
                .padding(.horizontal, TaktTheme.contentPadding)
                .padding(.bottom, 8)
            }
        }
        .coordinateSpace(name: "idle")
        // Floating animated thumbnail
        .overlay {
            if isAnimatingThumbnail,
               let imageData = viewModel.selectedImageData,
               let uiImage = UIImage(data: imageData) {
                let sourceCenter = lastInputWasCamera ? scanButtonCenter : attachButtonCenter
                let landingX = detectButtonFrame.minX + 34 // 16 offset + 18 half-width
                let landingY = detectButtonFrame.midY

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    .position(
                        x: thumbnailLanded ? landingX : sourceCenter.x,
                        y: thumbnailLanded ? landingY : sourceCenter.y
                    )
            }
        }
        .dropDestination(for: Data.self) { items, _ in
            guard let data = items.first,
                  let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.9) else { return false }
            viewModel.selectedImageData = jpeg
            Task { await viewModel.processImage() }
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(TaktTheme.accent, lineWidth: 3)
                    .background(TaktTheme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: viewModel.selectedImageData) { old, new in
            if old == nil && new != nil {
                startThumbnailAnimation()
            } else if new == nil {
                isAnimatingThumbnail = false
                thumbnailLanded = false
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoSheet()
                .presentationDetents([.medium])
        }
    }

    private func startThumbnailAnimation() {
        guard scanButtonCenter != .zero || attachButtonCenter != .zero else { return }

        thumbnailLanded = false
        isAnimatingThumbnail = true

        // Allow first frame to render at source position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
                thumbnailLanded = true
            }
        }

        // After animation settles, switch to static thumbnail on detect button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isAnimatingThumbnail = false
        }
    }
}

// MARK: - Info Sheet

private struct InfoSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WHAT WORKS")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(TaktTheme.textMuted)
                            .tracking(1)
                            .padding(.bottom, 2)

                        TipRow(text: "Concert tickets, posters, and flyers")
                        TipRow(text: "Food expiry labels and best-before dates")
                        TipRow(text: "Subscription renewal screenshots")
                        TipRow(text: "Receipts with deadlines and due dates")
                        TipRow(text: "Any text with a date in it")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("GOOD TO KNOW")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(TaktTheme.textMuted)
                            .tracking(1)
                            .padding(.bottom, 2)

                        TipRow(text: "Everything stays on your device — fully offline")
                        TipRow(text: "Detects dates, times, and deadlines automatically")
                        TipRow(text: "Supports German and English date formats")
                    }
                }
                .padding(TaktTheme.contentPadding)
            }
            .background(TaktTheme.appBackground)
            .navigationTitle("How it works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(TaktTheme.accent)
                }
            }
        }
    }
}

// MARK: - Or Separator

private struct OrSeparator: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(TaktTheme.cardBorder)
                .frame(height: 1)
            Text("or")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TaktTheme.textMuted)
            Rectangle()
                .fill(TaktTheme.cardBorder)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
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
        HStack(alignment: .top, spacing: 13) {
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
    var isDisabled: Bool = false
    let onPaste: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INPUT")
                .font(TaktTheme.cardLabelFont)
                .foregroundColor(TaktTheme.textMuted)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                TextField("Live Concert next Thursday at 20...", text: $text)
                    .textFieldStyle(.plain)
                    .font(TaktTheme.textFieldFont)
                    .foregroundColor(TaktTheme.textPrimary)
                    .disabled(isDisabled)

                if !isDisabled {
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
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TaktTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TaktTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: TaktTheme.cardCornerRadius)
                .stroke(TaktTheme.cardBorder, lineWidth: 1)
        )
        .opacity(isDisabled ? 0.4 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    ScanView(
        viewModel: ScanViewModel(
            textRecognitionService: DIContainer.shared.textRecognitionService,
            textEventParserService: DIContainer.shared.textEventParserService,
            addEventUseCase: DIContainer.shared.addEventUseCase,
            notificationService: DIContainer.shared.notificationService
        )
    )
}

#Preview {
    IdleStateView(viewModel: ScanViewModel(
        textRecognitionService: DIContainer.shared.textRecognitionService,
        textEventParserService: DIContainer.shared.textEventParserService,
        addEventUseCase: DIContainer.shared.addEventUseCase,
        notificationService: DIContainer.shared.notificationService
    ), showSuccessCheckmark: .constant(true))
}
