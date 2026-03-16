//
//  ImageInputButton.swift
//  Takt
//
//  Created by Artem Alekseev on 27.12.25.
//

import SwiftUI
import UIKit

struct ImageInputButton: View {
    let icon: String
    let label: String      // e.g. "CAPTURE"
    let title: String      // e.g. "Scan"
    @Binding var imageData: Data?
    let sourceType: SourceType
    var onTap: (() -> Void)? = nil

    @State private var selectedImage: UIImage?
    @State private var showingPicker = false

    enum SourceType {
        case camera
        case photoLibrary
    }

    var body: some View {
        Button {
            onTap?()
            showingPicker = true
        } label: {
            VStack(spacing: 8) {
                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(TaktsTheme.textMuted)

                Spacer()

                VStack(spacing: 2) {
                    Text(label)
                        .font(TaktsTheme.cardLabelFont)
                        .foregroundColor(TaktsTheme.textMuted)

                    Text(title)
                        .font(TaktsTheme.cardTitleFont)
                        .foregroundColor(TaktsTheme.textPrimary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 120)
            .aspectRatio(1, contentMode: .fit)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 0.15, alpha: 1.0)
                    : UIColor.white
            }))
            .clipShape(RoundedRectangle(cornerRadius: TaktsTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: TaktsTheme.cardCornerRadius)
                    .stroke(TaktsTheme.accent.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(PressScaleStyle())
        .sheet(isPresented: $showingPicker) {
            if sourceType == .camera {
                CameraView(selectedImage: $selectedImage)
            } else {
                PhotoPicker(selectedImage: $selectedImage)
            }
        }
        .onChange(of: selectedImage) { _, newImage in
            imageData = newImage?.jpegData(compressionQuality: 0.9)
        }
    }
}

// MARK: - Press Scale Button Style

private struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Note: PhotoPicker and CameraView are defined in ImagePickerView.swift
