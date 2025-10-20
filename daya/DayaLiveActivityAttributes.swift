import ActivityKit
import Foundation

struct DayaLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var simranDone: Bool
        var paathAngs: Int
    }
}

