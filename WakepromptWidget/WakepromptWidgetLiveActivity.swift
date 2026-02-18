//
//  WakepromptWidgetLiveActivity.swift
//  WakepromptWidget
//
//  Created by Davron Djabborov on 2026-02-17.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WakepromptWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WakepromptWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WakepromptWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension WakepromptWidgetAttributes {
    fileprivate static var preview: WakepromptWidgetAttributes {
        WakepromptWidgetAttributes(name: "World")
    }
}

extension WakepromptWidgetAttributes.ContentState {
    fileprivate static var smiley: WakepromptWidgetAttributes.ContentState {
        WakepromptWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WakepromptWidgetAttributes.ContentState {
         WakepromptWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WakepromptWidgetAttributes.preview) {
   WakepromptWidgetLiveActivity()
} contentStates: {
    WakepromptWidgetAttributes.ContentState.smiley
    WakepromptWidgetAttributes.ContentState.starEyes
}
