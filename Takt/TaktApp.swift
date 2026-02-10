//
//  TaktApp.swift
//  Takt
//
//  Created by Artem Alekseev on 11.06.25.
//

import SwiftUI

@main
struct TaktApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: DIContainer.shared.makeContentViewModel())
                .dismissKeyboardOnTap()
        }
    }
}
