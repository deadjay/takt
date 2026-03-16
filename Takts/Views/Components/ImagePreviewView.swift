//
//  ImagePreviewView.swift
//  Takt
//
//  Created by Artem Alekseev on 04.03.26.
//

import SwiftUI

/// Full-screen image preview with dismiss on tap or drag down.
struct ImagePreviewView: View {
    let imageData: Data
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(16)
            }
        }
        .statusBarHidden()
    }
}
