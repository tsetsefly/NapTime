import Foundation
import AVFoundation

class AlarmSoundManager {
    static let shared = AlarmSoundManager()

    private var player: AVAudioPlayer?

    private init() {}

    func startLoopingAlarm() {
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            print("Alarm sound file not found.")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // -1 means loop forever
            player?.volume = 1.0
            player?.prepareToPlay()
            player?.play()
            print("🔊 Alarm sound started")
        } catch {
            print("❌ Error playing alarm sound: \(error)")
        }
    }

    func stopAlarm() {
        player?.stop()
        print("🔇 Alarm sound stopped")
    }
}