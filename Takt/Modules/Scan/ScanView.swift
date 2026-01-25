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
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 48))
                        .foregroundColor(.cyan)

                    Text("Scan Document")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Point your camera, upload an image, or paste text to extract deadlines")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)

                // Input Methods
                VStack(spacing: 20) {
                    // Camera Button
                    ImageInputButton(
                        icon: "camera.fill",
                        title: "Scan with Camera",
                        imageData: $viewModel.selectedImageData,
                        sourceType: .camera
                    )

                    OrSeparator()

                    // Upload Button
                    ImageInputButton(
                        icon: "photo.fill",
                        title: "Upload Image",
                        imageData: $viewModel.selectedImageData,
                        sourceType: .photoLibrary
                    )

                    OrSeparator()

                    // Text Input Field with Paste Button
                    TextInputField(
                        text: $viewModel.inputText,
                        onPaste: {
                            viewModel.pasteFromClipboard()
                        }
                    )
                }
                .padding(.horizontal, 20)

                // Process Button (only show if input exists)
                if viewModel.selectedImageData != nil || !viewModel.inputText.isEmpty {
                    Button {
                        Task {
                            if viewModel.selectedImageData != nil {
                                await viewModel.processImage()
                            } else {
                                await viewModel.processText()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Extract Events")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer(minLength: 40)
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

private struct OrSeparator: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            Text("OR")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }
}

private struct TextInputField: View {
    @Binding var text: String
    let onPaste: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Type or paste text here e.g. /Cancel Amazon latest 25.06.2026/", text: $text)
                .textFieldStyle(.plain)
                .padding(.leading, 16)
                .padding(.vertical, 14)

            Button {
                onPaste()
            } label: {
                Text("Paste")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.trailing, 8)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
