import AlarmKit

nonisolated struct NapTimeMetadata: AlarmMetadata {
    var durationLabel: String
    var durationSeconds: Int
}
