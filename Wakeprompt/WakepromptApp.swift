//
//  WakepromptApp.swift
//  Wakeprompt
//
//  Created by Davron Djabborov on 2026-02-17.
//

import SwiftUI
import SwiftData

@main
struct WakepromptApp: App {
    var body: some Scene {
        WindowGroup {
            AlarmListView()
        }
        .modelContainer(for: Alarm.self)
    }
}
