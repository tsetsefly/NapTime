import Foundation
import AVFoundation

class AlarmSoundManager {
    static let shared = AlarmSoundManager()
    private var player: AVAudioPlayer?
    private var alreadyPlayedViaNotification = false

    private init() {}

    func startLoopingAlarm() {
        guard !alreadyPlayedViaNotification else {
            print("🔇 Skipping alarm — already played via notification.")
            return
        }

        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            print("Alarm sound file not found.")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 1.0
            player?.prepareToPlay()
            player?.play()
            print("🔊 Alarm sound started.")
        } catch {
            print("Error playing alarm sound: \(error)")
        }
    }

    func stopAlarm() {
        player?.stop()
        player = nil
        alreadyPlayedViaNotification = false // Reset for next time
        print("🔇 Alarm sound stopped.")
    }

    // Telling the system it already played the sound
    func markAlreadyPlayedViaNotification() {
        alreadyPlayedViaNotification = true
    }

    func resetPlaybackState() {
        alreadyPlayedViaNotification = false
    }
}