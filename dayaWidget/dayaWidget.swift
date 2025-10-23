import WidgetKit
import SwiftUI

struct WidgetHabit: Codable {
    let id: String
    let name: String
    let isVisible: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), habit1Name: "Nitnem", habit1Done: false, habit2Name: "Simran", habit2Done: false, streak: 0, weekProgress: Array(repeating: false, count: 7))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), habit1Name: "Nitnem", habit1Done: false, habit2Name: "Simran", habit2Done: false, streak: 0, weekProgress: Array(repeating: false, count: 7))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: today)
        
        // Load habit configuration
        var visibleHabits: [WidgetHabit] = []
        if let habitData = sharedDefaults?.data(forKey: "habit_config"),
           let habits = try? JSONDecoder().decode([WidgetHabit].self, from: habitData) {
            visibleHabits = habits.filter { $0.isVisible }
        }
        
        // Get first two habits
        let habit1 = visibleHabits.first
        let habit2 = visibleHabits.count > 1 ? visibleHabits[1] : nil
        
        // Get habit statuses
        let habit1Done: Bool
        if let habit1 = habit1 {
            if habit1.id == "sehaj_paath" {
                let angs = sharedDefaults?.integer(forKey: "paath_angs_\(todayKey)") ?? 0
                habit1Done = angs > 0
            } else if habit1.id == "morning_simran" {
                habit1Done = sharedDefaults?.object(forKey: "simran_\(todayKey)") as? Bool ?? false
            } else {
                habit1Done = sharedDefaults?.object(forKey: "\(habit1.id)_\(todayKey)") as? Bool ?? false
            }
        } else {
            habit1Done = false
        }
        
        let habit2Done: Bool
        if let habit2 = habit2 {
            if habit2.id == "sehaj_paath" {
                let angs = sharedDefaults?.integer(forKey: "paath_angs_\(todayKey)") ?? 0
                habit2Done = angs > 0
            } else if habit2.id == "morning_simran" {
                habit2Done = sharedDefaults?.object(forKey: "simran_\(todayKey)") as? Bool ?? false
            } else {
                habit2Done = sharedDefaults?.object(forKey: "\(habit2.id)_\(todayKey)") as? Bool ?? false
            }
        } else {
            habit2Done = false
        }
        
        // Calculate streak based on all visible habits
        var streak = 0
        var currentDate = today
        while true {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let key = dateFormatter.string(from: currentDate)
            
            var allDone = true
            for habit in visibleHabits {
                let done: Bool
                if habit.id == "sehaj_paath" {
                    let angs = sharedDefaults?.integer(forKey: "paath_angs_\(key)") ?? 0
                    done = angs > 0
                } else if habit.id == "morning_simran" {
                    done = sharedDefaults?.object(forKey: "simran_\(key)") as? Bool ?? false
                } else {
                    done = sharedDefaults?.object(forKey: "\(habit.id)_\(key)") as? Bool ?? false
                }
                
                if !done {
                    allDone = false
                    break
                }
            }
            
            if allDone && !visibleHabits.isEmpty {
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
            
            var allDone = true
            for habit in visibleHabits {
                let done: Bool
                if habit.id == "sehaj_paath" {
                    let angs = sharedDefaults?.integer(forKey: "paath_angs_\(key)") ?? 0
                    done = angs > 0
                } else if habit.id == "morning_simran" {
                    done = sharedDefaults?.object(forKey: "simran_\(key)") as? Bool ?? false
                } else {
                    done = sharedDefaults?.object(forKey: "\(habit.id)_\(key)") as? Bool ?? false
                }
                
                if !done {
                    allDone = false
                    break
                }
            }
            
            weekProgress.append(allDone && !visibleHabits.isEmpty)
        }
        
        let entry = SimpleEntry(
            date: today,
            habit1Name: habit1?.name ?? "No Habit",
            habit1Done: habit1Done,
            habit2Name: habit2?.name ?? "No Habit",
            habit2Done: habit2Done,
            streak: streak,
            weekProgress: weekProgress
        )
        
        // Refresh widget every 15 minutes for real-time updates
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: today)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let habit1Name: String
    let habit1Done: Bool
    let habit2Name: String
    let habit2Done: Bool
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
                    Text(entry.habit1Name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(entry.habit1Done ? "🏆" : "❌")
                        .font(.system(size: 18))
                }
                
                if entry.habit2Name != "No Habit" {
                    HStack(spacing: 6) {
                        Text(entry.habit2Name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(entry.habit2Done ? "🏆" : "❌")
                            .font(.system(size: 18))
                    }
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
                            Text(entry.habit1Name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(entry.habit1Done ? "🏆" : "❌")
                                .font(.system(size: 24))
                        }
                        
                        if entry.habit2Name != "No Habit" {
                            HStack(spacing: 8) {
                                Text(entry.habit2Name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(entry.habit2Done ? "🏆" : "❌")
                                    .font(.system(size: 24))
                            }
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
                    .widgetURL(URL(string: "daya://refresh"))
            } else {
                dayaWidgetEntryView(entry: entry, isSmall: false)
                    .widgetURL(URL(string: "daya://refresh"))
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
                    .widgetURL(URL(string: "daya://refresh"))
            } else {
                dayaWidgetEntryView(entry: entry, isSmall: true)
                    .widgetURL(URL(string: "daya://refresh"))
            }
        }
        .configurationDisplayName("Battle Stats Compact")
        .description("Track your daily progress.")
        .supportedFamilies([.systemSmall])
    }
}
