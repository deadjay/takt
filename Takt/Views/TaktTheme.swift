//
//  TaktTheme.swift
//  Takt
//
//  Design tokens from HTML Design Reference (02.2026)
//  Supports both light and dark mode automatically.
//

import SwiftUI
import UIKit

enum TaktTheme {
    // MARK: - Adaptive Colors (light / dark)

    /// Accent: #FF6500 (light) / #FF4D00 (dark)
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.302, blue: 0.0, alpha: 1.0)    // #FF4D00
            : UIColor(red: 1.0, green: 0.396, blue: 0.0, alpha: 1.0)    // #FF6500
    })

    /// App background: #F0F2F5 (light) / #141414 (dark)
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.078, green: 0.078, blue: 0.078, alpha: 1.0)  // #141414
            : UIColor(red: 0.941, green: 0.949, blue: 0.961, alpha: 1.0)  // #F0F2F5
    })

    /// Card background: white@0.82 (light) / white@0.03 (dark)
    static let cardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.03)
            : UIColor(white: 1.0, alpha: 0.82)
    })

    /// Card border: black@0.08 (light) / white@0.08 (dark)
    static let cardBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.08)
            : UIColor(white: 0.0, alpha: 0.08)
    })

    /// Primary text: #111827 (light) / #E5E5E7 (dark)
    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.898, green: 0.898, blue: 0.906, alpha: 1.0)  // #E5E5E7
            : UIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1.0)  // #111827
    })

    /// Secondary text: #4B5563 (light) / #8E8E93 (dark)
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0)  // #8E8E93
            : UIColor(red: 0.294, green: 0.333, blue: 0.388, alpha: 1.0)  // #4B5563
    })

    /// Muted text: #6B7280 (light) / #8E8E93 (dark)
    static let textMuted = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0)  // #8E8E93
            : UIColor(red: 0.420, green: 0.447, blue: 0.502, alpha: 1.0)  // #6B7280
    })

    // MARK: - Dimensions
    static let cardCornerRadius: CGFloat = 26
    static let magicButtonHeight: CGFloat = 78
    static let magicButtonCornerRadius: CGFloat = 20
    static let contentPadding: CGFloat = 24

    // MARK: - Fonts
    /// Card label: monospaced, small (e.g. "01 / CAPTURE")
    static let cardLabelFont = Font.system(size: 10, weight: .regular, design: .monospaced)

    /// Card title: 20pt, semibold (e.g. "Make Photo")
    static let cardTitleFont = Font.system(size: 20, weight: .semibold)

    /// Magic button: heavy, uppercase
    static let magicButtonFont = Font.system(size: 16, weight: .heavy)
}
