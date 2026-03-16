//
//  TextInputView.swift
//  Takt
//
//  Created by Artem Alekseev on 16.11.25.
//

import SwiftUI

struct TextInputView: View {
    @State private var viewModel: TextInputViewModel
    
    init(viewModel: TextInputViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // TODO: Implement UI
                Text("TextInput View")
            }
            .navigationTitle("TextInput")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
#Preview {
    TextInputView(
        viewModel: DIContainer.shared.makeTextInputViewModel())
}
