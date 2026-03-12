import SwiftUI
import AlarmKit
import ActivityKit

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

let debugAlarmOptions: [(label: String, seconds: Int)] = [
    ("3 seconds", 3),
    ("10 seconds", 10),
    ("30 seconds", 30),
    ("1 minute", 60),
]

struct ContentView: View {
    private let alarmManager = AlarmManager.shared

    @State private var authorizationState: AlarmManager.AuthorizationState = .notDetermined
    @State private var activeAlarm: Alarm?
    @State private var alarmFireDate: Date?
    @State private var errorMessage: String?
    @State private var debugMode = false

    private var visibleOptions: [(label: String, seconds: Int)] {
        debugMode ? debugAlarmOptions + alarmOptions : alarmOptions
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Text("NapTime Alarm")
                    .font(.largeTitle)
                Spacer()
            }
            .onTapGesture(count: 3) {
                debugMode.toggle()
            }

            // Authorization status (only shown in debug mode or when not authorized)
            if debugMode {
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
            } else if authorizationState == .denied {
                Text("Alarms Disabled — enable in Settings")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            if debugMode {
                Text("DEBUG MODE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
            }

            Divider()

            if let fireDate = alarmFireDate, activeAlarm != nil, fireDate > Date.now {
                // Countdown display
                VStack(spacing: 12) {
                    Text("Napping...")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text(timerInterval: Date.now ... fireDate, countsDown: true)
                        .font(.system(size: 64, weight: .thin, design: .rounded))
                        .monospacedDigit()

                    // Debug: active alarm info
                    if debugMode, let alarm = activeAlarm {
                        VStack(spacing: 4) {
                            Text("Alarm ID: \(alarm.id)")
                            Text("State: \(String(describing: alarm.state))")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

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
            } else {
                // Alarm buttons in a grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(visibleOptions, id: \.seconds) { option in
                        Button(action: {
                            Task {
                                await scheduleAlarm(seconds: option.seconds, label: option.label)
                            }
                        }) {
                            Text(option.label)
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(debugAlarmOptions.contains(where: { $0.seconds == option.seconds }) ? Color.orange : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .task {
            await requestAuthorization()
            // Cancel any leftover alarms from previous runs
            if let alarms = try? alarmManager.alarms {
                for alarm in alarms {
                    try? alarmManager.cancel(id: alarm.id)
                }
            }
        }
        .task {
            for await alarms in alarmManager.alarmUpdates {
                activeAlarm = alarms.first
                if alarms.isEmpty {
                    alarmFireDate = nil
                }
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
        // Ensure we have authorization before scheduling
        if alarmManager.authorizationState != .authorized {
            do {
                authorizationState = try await alarmManager.requestAuthorization()
            } catch {
                errorMessage = "Auth failed: \(error)"
                return
            }
            guard authorizationState == .authorized else {
                errorMessage = "Alarms not authorized (state: \(authorizationState))"
                return
            }
        }

        // Cancel any existing alarm first
        await cancelAlarm()

        let alert = AlarmPresentation.Alert(title: "Time to wake up!")
        let countdown = AlarmPresentation.Countdown(title: "Napping...")
        let presentation = AlarmPresentation(alert: alert, countdown: countdown)

        let metadata = NapTimeMetadata(durationLabel: label)

        let attributes = AlarmAttributes<NapTimeMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: .blue
        )

        do {
            let alarm = try await alarmManager.schedule(
                id: UUID(),
                configuration: .timer(
                    duration: TimeInterval(seconds),
                    attributes: attributes,
                    stopIntent: StopAlarmIntent()
                )
            )
            activeAlarm = alarm
            alarmFireDate = Date.now.addingTimeInterval(TimeInterval(seconds))
            errorMessage = nil
        } catch {
            errorMessage = "Schedule failed (auth: \(alarmManager.authorizationState)): \(error)"
        }
    }

    private func cancelAlarm() async {
        guard let alarm = activeAlarm else { return }
        do {
            try alarmManager.cancel(id: alarm.id)
            activeAlarm = nil
            alarmFireDate = nil
            errorMessage = nil
        } catch {
            errorMessage = "Failed to cancel alarm: \(error.localizedDescription)"
        }
    }
}
