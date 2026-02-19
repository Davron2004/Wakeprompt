# AlarmKit API Reference

Extracted from Xcode SDK headers (iOS 26.0+). Unavailable on macCatalyst.

---

## Alarm.Schedule

Two scheduling modes:

```swift
enum Alarm.Schedule: Codable, Equatable, Hashable, Sendable {
    case fixed(Date)                        // Absolute: fires at exact Date, ignores TZ changes
    case relative(Alarm.Schedule.Relative)  // Relative: fires at next occurrence of time-of-day, adjusts with TZ
}
```

### .fixed(Date)
- Takes a plain `Foundation.Date`
- Fires at that exact moment regardless of timezone changes
- One-shot only (no recurrence)
- Use for: one-time alarms on a specific future date

### .relative(Relative)
- Fires at the next occurrence of a time-of-day
- Adjusts automatically when device changes timezone (7 AM stays 7 AM local)
- Supports recurrence

```swift
struct Alarm.Schedule.Relative: Codable, Equatable, Sendable, Hashable {
    var time: Time
    var repeats: Recurrence

    struct Time: Codable, Equatable, Sendable, Hashable {
        var hour: Int       // 0-23
        var minute: Int     // 0-59
    }

    enum Recurrence: Codable, Equatable, Sendable, Hashable {
        case never                      // One-shot, fires at next occurrence
        case weekly([Locale.Weekday])   // Repeats on specified weekdays
    }
}
```

**Recurrence examples:**
```swift
// Every day at 7:00 AM
.weekly([.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday])

// Weekdays only
.weekly([.monday, .tuesday, .wednesday, .thursday, .friday])

// Just Mondays
.weekly([.monday])
```

---

## Alarm

```swift
struct Alarm: Identifiable, Codable, Sendable {
    typealias ID = UUID

    var id: UUID
    var schedule: Alarm.Schedule?
    var countdownDuration: CountdownDuration?
    var state: State

    struct CountdownDuration: Codable, Sendable, Equatable {
        var preAlert: TimeInterval?     // Countdown shown before alert
        var postAlert: TimeInterval?    // Time after alert before auto-stop
    }

    enum State: Equatable, Codable, Sendable, Hashable {
        case scheduled      // Waiting to fire
        case countdown      // Pre-alert countdown active
        case paused         // Countdown paused
        case alerting       // Currently firing
    }
}
```

---

## AlarmManager

Singleton. Manages all alarm lifecycle.

```swift
class AlarmManager {
    static let shared: AlarmManager

    // Authorization
    var authorizationState: AuthorizationState { get }
    var authorizationUpdates: some AsyncSequence<AuthorizationState, Never> { get }
    func requestAuthorization() async throws -> AuthorizationState

    enum AuthorizationState: Codable, Sendable, Equatable, Hashable {
        case notDetermined
        case denied
        case authorized
    }

    // Scheduling
    func schedule<Metadata: AlarmMetadata>(
        id: UUID,
        configuration: AlarmConfiguration<Metadata>
    ) async throws -> Alarm

    // Lifecycle
    func cancel(id: UUID) throws       // Cancel before firing
    func stop(id: UUID) throws          // Stop while alerting
    func countdown(id: UUID) throws     // Start pre-alert countdown
    func pause(id: UUID) throws         // Pause countdown
    func resume(id: UUID) throws        // Resume countdown

    // Observation
    var alarms: [Alarm] { get throws }
    var alarmUpdates: some AsyncSequence<[Alarm], Never> { get }

    enum AlarmError: Error, Equatable, Hashable {
        case maximumLimitReached
    }
}
```

---

## AlarmConfiguration

Factory for creating alarm or timer configurations.

```swift
struct AlarmManager.AlarmConfiguration<Metadata: AlarmMetadata> {
    // Full initializer
    init(
        countdownDuration: Alarm.CountdownDuration?,
        schedule: Alarm.Schedule?,
        attributes: AlarmAttributes<Metadata>,
        stopIntent: some LiveActivityIntent,
        secondaryIntent: (some LiveActivityIntent)?,
        sound: AlertConfiguration.AlertSound?
    )

    // Factory: scheduled alarm
    static func alarm(
        schedule: Alarm.Schedule? = nil,
        attributes: AlarmAttributes<Metadata>,
        stopIntent: some LiveActivityIntent,
        secondaryIntent: (some LiveActivityIntent)? = nil as Never?,
        sound: AlertConfiguration.AlertSound? = nil
    ) -> AlarmConfiguration<Metadata>

    // Factory: countdown timer
    static func timer(
        duration: TimeInterval,
        attributes: AlarmAttributes<Metadata>,
        stopIntent: some LiveActivityIntent,
        secondaryIntent: (some LiveActivityIntent)? = nil as Never?,
        sound: AlertConfiguration.AlertSound? = nil
    ) -> AlarmConfiguration<Metadata>
}
```

---

## AlarmAttributes

ActivityKit attributes for Live Activity / Dynamic Island display.

```swift
struct AlarmAttributes<Metadata: AlarmMetadata>: ActivityAttributes {
    typealias ContentState = AlarmPresentationState

    var presentation: AlarmPresentation
    var metadata: Metadata?
    var tintColor: Color
}
```

---

## AlarmPresentation

Controls the UI shown on lock screen / Dynamic Island.

```swift
struct AlarmPresentation: Codable, Sendable {
    var alert: Alert
    var countdown: Countdown?
    var paused: Paused?

    struct Alert: Codable, Sendable {
        var title: LocalizedStringResource
        var secondaryButton: AlarmButton?
        var secondaryButtonBehavior: SecondaryButtonBehavior?

        enum SecondaryButtonBehavior: Codable, Sendable, Hashable {
            case countdown      // Snooze-style countdown
            case custom         // Custom action
        }
    }

    struct Countdown: Codable, Sendable {
        var title: LocalizedStringResource
        var pauseButton: AlarmButton?
    }

    struct Paused: Codable, Sendable {
        var title: LocalizedStringResource
        var resumeButton: AlarmButton
    }
}
```

---

## AlarmButton

```swift
struct AlarmButton: Codable, Sendable {
    var text: LocalizedStringResource
    var textColor: Color
    var systemImageName: String
}
```

---

## AlarmPresentationState

Live Activity content state.

```swift
struct AlarmPresentationState: Codable, Sendable, Hashable {
    var alarmID: Alarm.ID
    var mode: Mode

    enum Mode: Codable, Equatable, Sendable, Hashable {
        case alert(Alert)
        case countdown(Countdown)
        case paused(Paused)

        struct Alert: Codable, Equatable, Sendable, Hashable {
            var time: Alarm.Schedule.Relative.Time
        }

        struct Countdown: Codable, Equatable, Sendable, Hashable {
            var totalCountdownDuration: TimeInterval
            var previouslyElapsedDuration: TimeInterval
            var startDate: Date
            var fireDate: Date
        }

        struct Paused: Codable, Equatable, Sendable, Hashable {
            var totalCountdownDuration: TimeInterval
            var previouslyElapsedDuration: TimeInterval
        }
    }
}
```

---

## AlarmMetadata (protocol)

Custom metadata attached to alarms. Must be Codable + Hashable + Sendable.

```swift
protocol AlarmMetadata: Decodable, Encodable, Hashable, Sendable {}
```

---

## AlertConfiguration.AlertSound

Used for alarm sounds (from ActivityKit):

```swift
.default                    // System default alarm sound
.named("filename.wav")      // Custom sound from Library/Sounds/
```

---

## Scheduling Decision Matrix

| Scenario | Schedule Type | Example |
|----------|--------------|---------|
| One-time alarm, specific date | `.fixed(date)` | "Wake me Feb 20 at 7 AM" |
| One-time alarm, next occurrence | `.relative(time, repeats: .never)` | "Wake me at 7 AM" |
| Daily recurring | `.relative(time, repeats: .weekly(allDays))` | "Every day at 7 AM" |
| Weekday recurring | `.relative(time, repeats: .weekly(weekdays))` | "Weekdays at 7 AM" |
| Specific days | `.relative(time, repeats: .weekly([.mon, .wed]))` | "Mon/Wed at 7 AM" |
| Countdown timer | Use `.timer(duration:...)` factory | "30 min timer" |
