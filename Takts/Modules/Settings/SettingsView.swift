//
//  SettingsView.swift
//  Takt
//
//  Created by Artem Alekseev on 04.03.26.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            TaktsTheme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                settingsHeader

                // Settings list
                ScrollView {
                    VStack(spacing: 24) {
                        appearanceSection
                    }
                    .padding(.horizontal, TaktsTheme.contentPadding)
                    .padding(.top, 8)
                }

                Spacer()
            }
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TAKT // SETTINGS")
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(TaktsTheme.accent)
                .tracking(2)

            Text("Settings")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(TaktsTheme.textPrimary)
                .tracking(-1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TaktsTheme.contentPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPEARANCE")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(TaktsTheme.textMuted)
                .tracking(1.5)

            VStack(spacing: 0) {
                ForEach(AppSettings.AppearanceMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.setAppearanceMode(mode)
                    } label: {
                        HStack {
                            Image(systemName: iconName(for: mode))
                                .font(.system(size: 16))
                                .foregroundColor(viewModel.appearanceMode == mode ? TaktsTheme.accent : TaktsTheme.textSecondary)
                                .frame(width: 24)

                            Text(displayName(for: mode))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(TaktsTheme.textPrimary)

                            Spacer()

                            if viewModel.appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(TaktsTheme.accent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if mode != AppSettings.AppearanceMode.allCases.last {
                        Divider()
                            .background(TaktsTheme.cardBorder)
                            .padding(.leading, 56)
                    }
                }
            }
            .background(TaktsTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(TaktsTheme.cardBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private func iconName(for mode: AppSettings.AppearanceMode) -> String {
        switch mode {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    private func displayName(for mode: AppSettings.AppearanceMode) -> String {
        switch mode {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
