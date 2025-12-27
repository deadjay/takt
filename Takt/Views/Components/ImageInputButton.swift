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
    let title: String
    @Binding var imageData: Data?
    let sourceType: SourceType

    @State private var selectedImage: UIImage?
    @State private var showingPicker = false

    enum SourceType {
        case camera
        case photoLibrary
    }

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
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
