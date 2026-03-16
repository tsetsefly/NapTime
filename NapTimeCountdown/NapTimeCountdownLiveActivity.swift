import ActivityKit
import AlarmKit
import AppIntents
import WidgetKit
import SwiftUI

struct NapTimeCountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<NapTimeMetadata>.self) { context in
            // Lock screen / banner UI
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NapTime")
                        .font(.headline)
                    CountdownTextView(state: context.state)
                        .font(.largeTitle)
                        .monospacedDigit()
                }

                Spacer()

                if case .countdown = context.state.mode {
                    HStack(spacing: 12) {
                        Button(intent: RestartAlarmIntent()) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 36))
                        }
                        .tint(.orange)

                        Button(intent: StopAlarmIntent()) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 36))
                        }
                        .tint(.red)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.blue.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("NapTime")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CountdownTextView(state: context.state)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        CountdownProgressView(state: context.state)
                            .frame(maxHeight: 30)
                        if case .countdown = context.state.mode {
                            Button(intent: RestartAlarmIntent()) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.title2)
                            }
                            .tint(.orange)
                            Button(intent: StopAlarmIntent()) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title2)
                            }
                            .tint(.red)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
            } compactTrailing: {
                CountdownTextView(state: context.state)
            } minimal: {
                Image(systemName: "alarm.fill")
            }
        }
    }
}

struct CountdownTextView: View {
    let state: AlarmPresentationState

    var body: some View {
        if case let .countdown(countdown) = state.mode {
            Text(timerInterval: Date.now ... countdown.fireDate)
                .monospacedDigit()
                .lineLimit(1)
        }
    }
}

struct CountdownProgressView: View {
    let state: AlarmPresentationState

    var body: some View {
        if case let .countdown(countdown) = state.mode {
            ProgressView(
                timerInterval: Date.now ... countdown.fireDate,
                label: { EmptyView() },
                currentValueLabel: { Text("") }
            )
            .progressViewStyle(.circular)
        }
    }
}
