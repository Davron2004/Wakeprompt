//
//  WakepromptWidgetBundle.swift
//  WakepromptWidget
//
//  Created by Davron Djabborov on 2026-02-17.
//

import WidgetKit
import SwiftUI

@main
struct WakepromptWidgetBundle: WidgetBundle {
    var body: some Widget {
        WakepromptWidget()
        WakepromptWidgetControl()
        WakepromptWidgetLiveActivity()
    }
}
