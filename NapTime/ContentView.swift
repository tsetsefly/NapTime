import SwiftUI
import AlarmKit

let alarmOptions: [(label: String, seconds: Int)] = [
    ("10 minutes", 600),
    ("13 minutes", 780),
    ("15 minutes", 900),
    ("20 minutes", 1200),
    ("23 minutes", 1380),
    ("25 minutes", 1500),
    ("45 minutes", 2700),
    ("60 minutes", 3600)
]

struct ContentView: View {
    private let alarmManager = AlarmManager.shared

    @State private var authorizationState: AlarmManager.AuthorizationState = .notDetermined
    @State private var activeAlarm: Alarm?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("NapTime Alarm")
                .font(.largeTitle)

            // Authorization status
            switch authorizationState {
            case .authorized:
                Text("Alarms Enabled")
                    .font(.subheadline)
                    .foregroundColor(.green)
            case .denied:
                Text("Alarms Disabled — enable in Settings")
                    .font(.subheadline)
                    .foregroundColor(.red)
            case .notDetermined:
                Text("Alarm permission not yet requested")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            @unknown default:
                EmptyView()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Divider()

            // Alarm buttons in a grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(alarmOptions, id: \.seconds) { option in
                    Button(action: {
                        Task {
                            await scheduleAlarm(seconds: option.seconds, label: option.label)
                        }
                    }) {
                        Text(option.label)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }

            Divider()

            // Active alarm info
            if let alarm = activeAlarm {
                Text("Alarm active: \(alarm.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Cancel alarm button
            Button(action: {
                Task {
                    await cancelAlarm()
                }
            }) {
                Text("Stop Alarm")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .task {
            await requestAuthorization()
        }
        .task {
            for await alarms in alarmManager.alarmUpdates {
                activeAlarm = alarms.first
            }
        }
    }

    private func requestAuthorization() async {
        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                authorizationState = try await alarmManager.requestAuthorization()
            } catch {
                errorMessage = "Failed to request alarm permission: \(error.localizedDescription)"
            }
        case .authorized, .denied:
            authorizationState = alarmManager.authorizationState
        @unknown default:
            break
        }
    }

    private func scheduleAlarm(seconds: Int, label: String) async {
        // Cancel any existing alarm first
        await cancelAlarm()

        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .white,
            systemImageName: "stop.circle"
        )

        let alert = AlarmPresentation.Alert(
            title: "Time to wake up!",
            stopButton: stopButton
        )

        let metadata = NapTimeMetadata(durationLabel: label)

        let attributes = AlarmAttributes<NapTimeMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: metadata,
            tintColor: .blue
        )

        let sound = AlarmConfiguration.AlertSound.named("alarm")

        do {
            let alarm = try await alarmManager.schedule(
                id: UUID(),
                configuration: .timer(
                    duration: TimeInterval(seconds),
                    attributes: attributes,
                    sound: sound
                )
            )
            activeAlarm = alarm
            errorMessage = nil
        } catch {
            errorMessage = "Failed to schedule alarm: \(error.localizedDescription)"
        }
    }

    private func cancelAlarm() async {
        guard let alarm = activeAlarm else { return }
        do {
            try await alarmManager.cancel(id: alarm.id)
            activeAlarm = nil
            errorMessage = nil
        } catch {
            errorMessage = "Failed to cancel alarm: \(error.localizedDescription)"
        }
    }
}
