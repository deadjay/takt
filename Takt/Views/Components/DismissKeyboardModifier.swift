//
//  DismissKeyboardModifier.swift
//  Takt
//
//  Dismiss keyboard on tap outside a text field and on scroll.
//

import SwiftUI
import UIKit

// MARK: - ViewModifier

struct DismissKeyboardModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Scroll dismiss: every UIScrollView (Form, List, ScrollView)
                // will dismiss the keyboard when the user starts dragging.
                UIScrollView.appearance().keyboardDismissMode = .interactive

                // Tap dismiss: add a gesture recognizer to the key window
                // that fires alongside other touches (cancelsTouchesInView = false).
                DispatchQueue.main.async {
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = scene.windows.first else { return }

                    // Avoid adding duplicates if view re-appears
                    let tag = "TaktKeyboardDismiss"
                    if window.gestureRecognizers?.contains(where: { $0.name == tag }) == true {
                        return
                    }

                    let tap = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing(_:)))
                    tap.cancelsTouchesInView = false
                    tap.name = tag
                    window.addGestureRecognizer(tap)
                }
            }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardModifier())
    }
}
