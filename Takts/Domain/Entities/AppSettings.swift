//
//  AppSettings.swift
//  Takt
//
//  Created by Artem Alekseev on 04.03.26.
//

import Foundation

struct AppSettings {
    enum AppearanceMode: String, Codable, CaseIterable {
        case system
        case light
        case dark
    }

    var appearanceMode: AppearanceMode = .system
}
