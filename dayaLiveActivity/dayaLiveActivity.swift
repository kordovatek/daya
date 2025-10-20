import ActivityKit
import WidgetKit
import SwiftUI

struct DayaLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var simranDone: Bool
        var paathAngs: Int
    }
}

struct DayaLiveActivityView: View {
    let context: ActivityViewContext<DayaLiveActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(context.state.simranDone ? "🏆" : "⭕️")
                        .font(.system(size: 20))
                    Text("Morning Simran")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 6) {
                    Text(context.state.paathAngs > 0 ? "✅" : "⭕️")
                        .font(.system(size: 20))
                    Text("Sehaj Paath")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    if context.state.paathAngs > 0 {
                        Text("\(context.state.paathAngs) angs")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                let completed = (context.state.simranDone ? 1 : 0) + (context.state.paathAngs > 0 ? 1 : 0)
                Text("\(completed)/2")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(completed == 2 ? .green : Color(red: 1.0, green: 0.84, blue: 0.0))
                Text("Complete")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.08, green: 0.12, blue: 0.20)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

@available(iOS 16.2, *)
struct DayaLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayaLiveActivityAttributes.self) { context in
            DayaLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.simranDone ? "🏆" : "⭕️")
                        .font(.system(size: 24))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.paathAngs > 0 ? "✅" : "⭕️")
                        .font(.system(size: 24))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Morning Simran")
                            .font(.system(size: 12))
                        Spacer()
                        Text("Sehaj Paath")
                            .font(.system(size: 12))
                    }
                }
            } compactLeading: {
                let completed = (context.state.simranDone ? 1 : 0) + (context.state.paathAngs > 0 ? 1 : 0)
                Text("\(completed)/2")
                    .font(.system(size: 12, weight: .semibold))
            } compactTrailing: {
                Text(context.state.simranDone && context.state.paathAngs > 0 ? "✅" : "⭕️")
                    .font(.system(size: 14))
            } minimal: {
                Text(context.state.simranDone && context.state.paathAngs > 0 ? "✅" : "⭕️")
                    .font(.system(size: 12))
            }
        }
    }
}

