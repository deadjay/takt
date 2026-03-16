//
//  UserDefaultsSettingsRepository.swift
//  Takt
//
//  Created by Artem Alekseev on 04.03.26.
//

import Foundation

protocol SettingsRepositoryProtocol {
    func getSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
}

final class UserDefaultsSettingsRepository: SettingsRepositoryProtocol {

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let appearanceModeKey = "AppearanceMode"

    // MARK: - Init
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - SettingsRepositoryProtocol

    func getSettings() -> AppSettings {
        var settings = AppSettings()

        if let rawValue = userDefaults.string(forKey: appearanceModeKey),
           let mode = AppSettings.AppearanceMode(rawValue: rawValue) {
            settings.appearanceMode = mode
        }

        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        userDefaults.set(settings.appearanceMode.rawValue, forKey: appearanceModeKey)
    }
}
