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
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(TaktTheme.textMuted)

                Spacer()

                Text(label)
                    .font(TaktTheme.cardLabelFont)
                    .foregroundColor(TaktTheme.textMuted)

                Text(title)
                    .font(TaktTheme.cardTitleFont)
                    .foregroundColor(TaktTheme.textPrimary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
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
