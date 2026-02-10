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
    let label: String      // e.g. "01 / CAPTURE"
    let title: String      // e.g. "Make Photo"
    @Binding var imageData: Data?
    let sourceType: SourceType

    @State private var selectedImage: UIImage?
    @State private var showingPicker = false

    enum SourceType {
        case camera
        case photoLibrary
    }

    var body: some View {
        // TODO: You implement the card design here!
        // Design spec:
        // - Square card, fills available width (use .frame(maxWidth: .infinity))
        // - Aspect ratio 1:1 (square)
        // - Background: TaktTheme.cardBackground
        // - Corner radius: TaktTheme.cardCornerRadius (26pt)
        // - Border: 1px TaktTheme.cardBorder
        // - Content aligned bottom-left:
        //   - Label text (e.g. "01 / CAPTURE") in TaktTheme.cardLabelFont, TaktTheme.textMuted color
        //   - Title text (e.g. "Make Photo") in TaktTheme.cardTitleFont, TaktTheme.textPrimary color
        // - Padding: 24pt inside
        //
        // Wrap everything in a Button that sets showingPicker = true
        // Keep the .sheet and .onChange modifiers below

        Button {
            showingPicker = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text(label.uppercased())
                    .font(TaktTheme.cardLabelFont)
                    .foregroundColor(TaktTheme.textMuted)
                Text(title)
                    .font(TaktTheme.cardTitleFont)
                    .foregroundColor(TaktTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .aspectRatio(1, contentMode: .fit)
            .background(TaktTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: TaktTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: TaktTheme.cardCornerRadius)
                    .stroke(TaktTheme.cardBorder, lineWidth: 1)
            )
        }
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

// Note: PhotoPicker and CameraView are defined in ImagePickerView.swift
