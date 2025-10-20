import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), simranDone: false, paathAngs: 0, streak: 0, weekProgress: Array(repeating: false, count: 7))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), simranDone: false, paathAngs: 0, streak: 0, weekProgress: Array(repeating: false, count: 7))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
        
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: today)
        
        let simranDone = sharedDefaults?.object(forKey: "simran_\(todayKey)") as? Bool ?? false
        let paathAngs = sharedDefaults?.integer(forKey: "paath_angs_\(todayKey)") ?? 0
        
        // Calculate streak
        var streak = 0
        var currentDate = today
        while true {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let key = dateFormatter.string(from: currentDate)
            let simran = sharedDefaults?.object(forKey: "simran_\(key)") as? Bool ?? false
            let paath = sharedDefaults?.integer(forKey: "paath_angs_\(key)") ?? 0
            
            if simran && paath > 0 {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        // Get week progress
        var weekProgress: [Bool] = []
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = (weekday - 1) % 7
        let mostRecentSunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today)!
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: mostRecentSunday)!
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let key = dateFormatter.string(from: date)
            let simran = sharedDefaults?.object(forKey: "simran_\(key)") as? Bool ?? false
            let paath = sharedDefaults?.integer(forKey: "paath_angs_\(key)") ?? 0
            weekProgress.append(simran && paath > 0)
        }
        
        let entry = SimpleEntry(
            date: today,
            simranDone: simranDone,
            paathAngs: paathAngs,
            streak: streak,
            weekProgress: weekProgress
        )
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let simranDone: Bool
    let paathAngs: Int
    let streak: Int
    let weekProgress: [Bool]
}

struct dayaWidgetEntryView : View {
    var entry: Provider.Entry
    var isSmall: Bool = false

    var body: some View {
        if isSmall {
            VStack(alignment: .leading, spacing: 8) {
                Text("Battle Stats")
                    .font(.custom("Georgia-Bold", size: 18.2))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                HStack(spacing: 6) {
                    Text("Simran")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(entry.simranDone ? "🏆" : "❌")
                        .font(.system(size: 18))
                }
                
                HStack(spacing: 6) {
                    Text("Sehaj Paath")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(entry.paathAngs > 0 ? "🏆" : "❌")
                        .font(.system(size: 18))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(entry.streak)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                    Text("🔥")
                        .font(.system(size: 20))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
        } else {
            VStack(spacing: 12) {
                Text("Battle Stats")
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("Morning Simran")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text(entry.simranDone ? "🏆" : "❌")
                                .font(.system(size: 24))
                        }
                        
                        HStack(spacing: 8) {
                            Text("Sehaj Paath")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text(entry.paathAngs > 0 ? "🏆" : "❌")
                                .font(.system(size: 24))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("\(entry.streak) 🔥")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                        
                        HStack(spacing: 4) {
                            ForEach(0..<min(7, entry.weekProgress.count), id: \.self) { i in
                                Circle()
                                    .fill(entry.weekProgress[i] ? Color.green : Color.white.opacity(0.2))
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

struct dayaMediumWidget: Widget {
    let kind: String = "com.daya.daya.dayaWidget.medium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                dayaWidgetEntryView(entry: entry, isSmall: false)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.05, green: 0.08, blue: 0.15),
                                Color(red: 0.08, green: 0.12, blue: 0.20)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                dayaWidgetEntryView(entry: entry, isSmall: false)
            }
        }
        .configurationDisplayName("Battle Stats")
        .description("Track your daily progress.")
        .supportedFamilies([.systemMedium])
    }
}

struct dayaSmallWidget: Widget {
    let kind: String = "com.daya.daya.dayaWidget.small"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                dayaWidgetEntryView(entry: entry, isSmall: true)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.05, green: 0.08, blue: 0.15),
                                Color(red: 0.08, green: 0.12, blue: 0.20)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                dayaWidgetEntryView(entry: entry, isSmall: true)
            }
        }
        .configurationDisplayName("Battle Stats Compact")
        .description("Track your daily progress.")
        .supportedFamilies([.systemSmall])
    }
}
