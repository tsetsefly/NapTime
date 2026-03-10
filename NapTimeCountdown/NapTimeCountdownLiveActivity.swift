import ActivityKit
import AlarmKit
import WidgetKit
import SwiftUI

struct NapTimeCountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<NapTimeMetadata>.self) { context in
            // Lock screen / banner UI
            VStack(spacing: 8) {
                Text("NapTime")
                    .font(.headline)
                CountdownTextView(state: context.state)
                    .font(.largeTitle)
                    .monospacedDigit()
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
                    CountdownProgressView(state: context.state)
                        .frame(maxHeight: 30)
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
