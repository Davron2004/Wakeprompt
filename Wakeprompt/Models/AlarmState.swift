import Foundation

enum AlarmState: String, Codable, Sendable {
    case draft
    case generatingText
    case generatingAudio
    case armingPrimaryAlarm
    case armingFallbackAlarm
    case armed
    case firedPrimary
    case firedFallback
    case completed
    case failedAudibly
    case errorBlocked

    var isTerminal: Bool {
        switch self {
        case .completed, .failedAudibly, .errorBlocked:
            return true
        default:
            return false
        }
    }

    var isGenerating: Bool {
        switch self {
        case .generatingText, .generatingAudio:
            return true
        default:
            return false
        }
    }

    var displayLabel: String {
        switch self {
        case .draft: return "Draft"
        case .generatingText: return "Generating text…"
        case .generatingAudio: return "Generating audio…"
        case .armingPrimaryAlarm: return "Arming…"
        case .armingFallbackAlarm: return "Arming fallback…"
        case .armed: return "Armed"
        case .firedPrimary: return "Fired (AI)"
        case .firedFallback: return "Fired (Fallback)"
        case .completed: return "Completed"
        case .failedAudibly: return "Failed (audible)"
        case .errorBlocked: return "Error"
        }
    }
}
