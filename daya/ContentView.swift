import SwiftUI
import ActivityKit
import UserNotifications

struct DayaLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var simranDone: Bool
        var paathAngs: Int
    }
}

struct Habit: Identifiable, Codable {
    let id: String
    var name: String
    var emoji: String
    var isVisible: Bool
    let isSystem: Bool
    
    static let morningSimran = Habit(id: "morning_simran", name: "Morning Simran", emoji: "🏆", isVisible: true, isSystem: true)
    static let sehajPaath = Habit(id: "sehaj_paath", name: "Sehaj Paath", emoji: "📖", isVisible: true, isSystem: true)
}

class HabitConfig: ObservableObject {
    @Published var habits: [Habit] = []
    private let defaults = UserDefaults.standard
    private let key = "habit_config"
    
    init() {
        loadHabits()
    }
    
    func loadHabits() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        } else {
            habits = [.morningSimran, .sehajPaath]
            saveHabits()
        }
    }
    
    func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    func addHabit(name: String, emoji: String = "") {
        let habit = Habit(id: UUID().uuidString, name: name, emoji: emoji, isVisible: true, isSystem: false)
        habits.append(habit)
        saveHabits()
    }
    
    func moveHabit(from: IndexSet, to: Int) {
        habits.move(fromOffsets: from, toOffset: to)
        saveHabits()
    }
    
    func toggleVisibility(for id: String) {
        if let index = habits.firstIndex(where: { $0.id == id }) {
            habits[index].isVisible.toggle()
            saveHabits()
        }
    }
    
    func deleteHabit(id: String) {
        habits.removeAll { $0.id == id && !$0.isSystem }
        saveHabits()
    }
    
    var visibleHabits: [Habit] {
        habits.filter { $0.isVisible }
    }
    
    func isVisible(_ habitId: String) -> Bool {
        habits.first(where: { $0.id == habitId })?.isVisible ?? false
    }
}

struct ContentView: View {
    @StateObject private var simranTracker = HabitTracker()
    @StateObject private var paathTracker = SehajPaathTracker()
    @StateObject private var habitConfig = HabitConfig()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.08, green: 0.12, blue: 0.20)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                TabView(selection: $selectedTab) {
                    TodayView(simranTracker: simranTracker, paathTracker: paathTracker, habitConfig: habitConfig)
                        .tag(0)
                    
                    CalendarTabView(simranTracker: simranTracker, paathTracker: paathTracker, habitConfig: habitConfig)
                        .tag(1)
                    
                    SettingsView(habitConfig: habitConfig)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Liquid glass tab bar
                HStack(spacing: 20) {
                    TabBarButton(icon: "house.fill", isSelected: selectedTab == 0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 0
                        }
                    }
                    
                    TabBarButton(icon: "calendar", isSelected: selectedTab == 1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 1
                        }
                    }
                    
                    TabBarButton(icon: "gearshape.fill", isSelected: selectedTab == 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 2
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    ZStack {
                        // Blurred transparent background
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.ultraThinMaterial.opacity(0.8))
                        
                        // Semi-transparent dark overlay
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(red: 0.05, green: 0.08, blue: 0.15).opacity(0.3))
                        
                        // Border stroke
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                        
                        // Subtle highlight
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.15))
                        .frame(width: 52, height: 52)
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white.opacity(0.5))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TodayView: View {
    @ObservedObject var simranTracker: HabitTracker
    @ObservedObject var paathTracker: SehajPaathTracker
    @ObservedObject var habitConfig: HabitConfig
    @State private var showTargetDatePicker = false
    @State private var showPaathEditor = false
    @State private var showSimranInfo = false
    @State private var angsInput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Simplicity Compounds ⭐️")
                        .font(.custom("Georgia-Bold", size: 26))
                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.top, 40)
                
                // Morning Simran Widget
                if habitConfig.isVisible("morning_simran") {
                    WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Morning Simran")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            
                            Button(action: {
                                showSimranInfo.toggle()
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                        
                        if showSimranInfo {
                            Text("Complete morning simran by attending sangat at a Gurdwara or doing at least 30 minutes of meditation on your own between 2:00 AM and 6:30 AM.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                if simranTracker.isCompletedToday {
                                    simranTracker.clearToday()
                                } else {
                                    simranTracker.markToday(completed: true)
                                }
                            }) {
                                Text("🏆")
                                    .font(.system(size: 32))
                                    .frame(width: 80, height: 44)
                                    .background(simranTracker.isCompletedToday ? Color.green.opacity(0.4) : Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(simranTracker.isCompletedToday ? Color.green : Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            
                            Button(action: {
                                if simranTracker.isCompletedToday == false && simranTracker.hasAnsweredToday {
                                    simranTracker.clearToday()
                                } else {
                                    simranTracker.markToday(completed: false)
                                }
                            }) {
                                Text("❌")
                                    .font(.system(size: 32))
                                    .frame(width: 80, height: 44)
                                    .background(simranTracker.isCompletedToday == false && simranTracker.hasAnsweredToday ? Color.red.opacity(0.4) : Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(simranTracker.isCompletedToday == false && simranTracker.hasAnsweredToday ? Color.red : Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(simranTracker.last7Days, id: \.date) { day in
                                VStack(spacing: 6) {
                                    Text(day.dayLabel)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                    
                                    Circle()
                                        .fill(day.completed == true ? Color.green : day.completed == false ? Color.red.opacity(0.5) : Color.white.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                }
                            }
                        }
                    }
                    }
                }
                
                // Sehaj Paath Widget
                if habitConfig.isVisible("sehaj_paath") {
                    WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Sehaj Paath")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                        }
                        
                        if showPaathEditor {
                            VStack(spacing: 12) {
                                VStack(spacing: 8) {
                                    Text("Angs Read Today")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    HStack(spacing: 12) {
                                        TextField("0", text: $angsInput)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 80, height: 44)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                            )
                                            .onAppear {
                                                angsInput = "\(paathTracker.angsReadToday)"
                                            }
                                        
                                        Button(action: {
                                            if let angs = Int(angsInput), angs >= 0 {
                                                paathTracker.setAngsForToday(angs)
                                            }
                                        }) {
                                            Text("Save")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(Color.green.opacity(0.4))
                                                .cornerRadius(8)
                                        }
                                    }
                                    
                                    Text("Current: \(paathTracker.angsReadToday) angs")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                Button(action: {
                                    showTargetDatePicker.toggle()
                                }) {
                                    Text(paathTracker.targetDate == nil ? "Set Target Date" : "Target: \(paathTracker.formattedTargetDate)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .sheet(isPresented: $showTargetDatePicker) {
                                    VStack(spacing: 20) {
                                        Text("Select Target Date")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.top, 20)
                                        
                                        DatePicker("", selection: Binding(
                                            get: { paathTracker.targetDate ?? Date().addingTimeInterval(86400 * 30) },
                                            set: { paathTracker.targetDate = $0 }
                                        ), displayedComponents: .date)
                                            .datePickerStyle(.wheel)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                        
                                        Button(action: {
                                            showTargetDatePicker = false
                                        }) {
                                            Text("Done")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 14)
                                                .background(Color.green.opacity(0.4))
                                                .cornerRadius(10)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 20)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(red: 0.05, green: 0.08, blue: 0.15))
                                    .presentationDetents([.medium])
                                }
                                
                                Button(action: {
                                    showPaathEditor = false
                                    angsInput = ""
                                }) {
                                    Text("Done")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.green.opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("\(paathTracker.percentComplete, specifier: "%.1f")%")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                    Text("(\(paathTracker.currentAng) Angs)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.leading, 4)
                                    Spacer()
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                                            .frame(width: geometry.size.width * CGFloat(paathTracker.percentComplete / 100), height: 8)
                                    }
                                }
                                .frame(height: 8)
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(paathTracker.angsReadToday)")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                        Text("Today")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(paathTracker.dailyAverage, specifier: "%.1f")")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                        Text("Daily Avg")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    if let required = paathTracker.requiredDailyAngs {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(required, specifier: "%.1f")")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(Color.yellow.opacity(0.9))
                                            Text("Required")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(paathTracker.estimatedFinishDate)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                        Text("Est. Pogh")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(paathTracker.targetDate == nil ? "—" : paathTracker.formattedTargetDate)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                        Text("Target")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(paathTracker.last7DaysProgress(), id: \.date) { day in
                                VStack(spacing: 6) {
                                    Text(day.dayLabel)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                    
                                    Circle()
                                        .fill(day.completed ? Color.green : Color.white.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !showPaathEditor {
                            showPaathEditor = true
                        }
                    }
                    }
                }
                
                // Custom Habits
                ForEach(habitConfig.habits.filter { !$0.isSystem && $0.isVisible }) { habit in
                    CustomHabitWidget(habit: habit, tracker: HabitTracker(prefix: habit.id))
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

struct CustomHabitWidget: View {
    let habit: Habit
    @ObservedObject var tracker: HabitTracker
    
    var body: some View {
        WidgetCard {
            VStack(spacing: 16) {
                HStack {
                    Text(habit.emoji.isEmpty ? habit.name : "\(habit.emoji) \(habit.name)")
                        .font(.custom("Georgia-Bold", size: 22))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        if tracker.isCompletedToday {
                            tracker.clearToday()
                        } else {
                            tracker.markToday(completed: true)
                        }
                    }) {
                        Text("✅")
                            .font(.system(size: 32))
                            .frame(width: 80, height: 44)
                            .background(tracker.isCompletedToday ? Color.green.opacity(0.4) : Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(tracker.isCompletedToday ? Color.green : Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                    
                    Button(action: {
                        if tracker.isCompletedToday == false && tracker.hasAnsweredToday {
                            tracker.clearToday()
                        } else {
                            tracker.markToday(completed: false)
                        }
                    }) {
                        Text("❌")
                            .font(.system(size: 32))
                            .frame(width: 80, height: 44)
                            .background(tracker.isCompletedToday == false && tracker.hasAnsweredToday ? Color.red.opacity(0.4) : Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(tracker.isCompletedToday == false && tracker.hasAnsweredToday ? Color.red : Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
                
                HStack(spacing: 8) {
                    ForEach(tracker.last7Days, id: \.date) { day in
                        VStack(spacing: 6) {
                            Text(day.dayLabel)
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                            
                            Circle()
                                .fill(day.completed == true ? Color.green : day.completed == false ? Color.red.opacity(0.5) : Color.white.opacity(0.2))
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }
        }
    }
}

struct CalendarTabView: View {
    @ObservedObject var simranTracker: HabitTracker
    @ObservedObject var paathTracker: SehajPaathTracker
    @ObservedObject var habitConfig: HabitConfig
    @State private var selectedDate: Date?
    @State private var showEditSheet = false
    @State private var historicalAngsInput: String = ""
    @State private var historicalSimranStatus: Bool? = nil
    @State private var currentCalendarMonth: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Calendar")
                        .font(.custom("Georgia-Bold", size: 26))
                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                    Spacer()
                }
                .padding(.top, 40)
                
                // Calendar Widget
                WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: {
                                currentCalendarMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentCalendarMonth) ?? currentCalendarMonth
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            }
                            
                            Text(formatMonthYear(currentCalendarMonth))
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            
                            Button(action: {
                                currentCalendarMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentCalendarMonth) ?? currentCalendarMonth
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            }
                            
                            Spacer()
                            
                            Text("\(paathTracker.combinedStreak(with: simranTracker)) 🔥")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                        }
                        
                        CalendarGridView(
                            simranTracker: simranTracker,
                            paathTracker: paathTracker,
                            selectedDate: $selectedDate,
                            displayMonth: currentCalendarMonth
                        )
                    }
                }
                
                // Selected Day Details Widget
                if let selected = selectedDate {
                    WidgetCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text(formatDateHeader(selected))
                                    .font(.custom("Georgia-Bold", size: 20))
                                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        selectedDate = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            
                            HStack(spacing: 40) {
                                VStack(spacing: 8) {
                                    Text("Morning Simran")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(simranTracker.isCompleted(on: selected) ? "✅" : "—")
                                        .font(.system(size: 24))
                                }
                                
                                VStack(spacing: 8) {
                                    Text("Sehaj Paath")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("\(paathTracker.getAngsForDate(selected)) angs")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                }
                            }
                            
                            Text("Tap to edit")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 4)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            historicalAngsInput = "\(paathTracker.getAngsForDate(selected))"
                            historicalSimranStatus = simranTracker.isCompleted(on: selected) ? true : nil
                            showEditSheet = true
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .sheet(isPresented: $showEditSheet) {
                        if let selected = selectedDate {
                            EditDaySheet(
                                date: selected,
                                simranTracker: simranTracker,
                                paathTracker: paathTracker,
                                historicalAngsInput: $historicalAngsInput,
                                historicalSimranStatus: $historicalSimranStatus,
                                isPresented: $showEditSheet
                            )
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
    
    func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct EditDaySheet: View {
    let date: Date
    @ObservedObject var simranTracker: HabitTracker
    @ObservedObject var paathTracker: SehajPaathTracker
    @Binding var historicalAngsInput: String
    @Binding var historicalSimranStatus: Bool?
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text(formatDateHeader(date))
                    .font(.custom("Georgia-Bold", size: 24))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 32) {
                // Morning Simran Section
                VStack(spacing: 16) {
                    Text("Morning Simran")
                        .font(.custom("Georgia-Bold", size: 20))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            historicalSimranStatus = true
                        }) {
                            VStack(spacing: 8) {
                                Text("✅")
                                    .font(.system(size: 40))
                                Text("Done")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(historicalSimranStatus == true ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(historicalSimranStatus == true ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                            )
                        }
                        
                        Button(action: {
                            historicalSimranStatus = false
                        }) {
                            VStack(spacing: 8) {
                                Text("❌")
                                    .font(.system(size: 40))
                                Text("Not Done")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(historicalSimranStatus == false ? Color.red.opacity(0.3) : Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(historicalSimranStatus == false ? Color.red : Color.white.opacity(0.2), lineWidth: 2)
                            )
                        }
                        
                        Button(action: {
                            historicalSimranStatus = nil
                        }) {
                            VStack(spacing: 8) {
                                Text("—")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Clear")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(historicalSimranStatus == nil ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(historicalSimranStatus == nil ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 2)
                            )
                        }
                    }
                }
                
                // Sehaj Paath Section
                VStack(spacing: 16) {
                    Text("Sehaj Paath")
                        .font(.custom("Georgia-Bold", size: 20))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        Text("Angs Read")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("0", text: $historicalAngsInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
            }
            
            Spacer()
            
            // Save Button
            Button(action: {
                if let angs = Int(historicalAngsInput) {
                    paathTracker.setAngsForDate(angs, date: date)
                }
                
                if let simranStatus = historicalSimranStatus {
                    simranTracker.markHistoricalDate(date, completed: simranStatus)
                } else {
                    simranTracker.clearHistoricalDate(date)
                }
                
                isPresented = false
            }) {
                Text("Save Changes")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.8, green: 0.67, blue: 0.0))
                    .cornerRadius(12)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.08, blue: 0.15))
    }
    
    func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

struct SettingsView: View {
    @ObservedObject var habitConfig: HabitConfig
    
    @State private var dailyRemindersEnabled = false
    @State private var reminderFrequency = 1
    @State private var reminderTime1 = Date()
    @State private var reminderTime2 = Date()
    @State private var reminderTime3 = Date()
    
    @State private var quoteNotificationsEnabled = false
    @State private var morningQuotesEnabled = false
    @State private var afternoonQuotesEnabled = false
    @State private var nightQuotesEnabled = false
    
    @State private var quotes: [String] = []
    @State private var newQuote = ""
    @State private var showingQuoteInput = false
    
    @State private var newHabitName = ""
    @State private var newHabitEmoji = ""
    @State private var showingHabitInput = false
    @State private var habitToDelete: Habit?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("Settings")
                        .font(.custom("Georgia-Bold", size: 26))
                        .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                    Spacer()
                }
                .padding(.top, 40)
                
                // FYI Message
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daya will always be free, and is a passion project by Kordova Tek Inc.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Link(destination: URL(string: "mailto:mk@kordovatek.com?subject=Feature%20Request")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14))
                            Text("Send Feature Request")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // Habit Management
                WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Manage Habits")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                            
                            Button(action: {
                                showingHabitInput.toggle()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            }
                        }
                        
                        if showingHabitInput {
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    TextField("Emoji (optional)", text: $newHabitEmoji)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 80, height: 44)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    TextField("Habit name...", text: $newHabitName)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showingHabitInput = false
                                        newHabitName = ""
                                        newHabitEmoji = ""
                                    }) {
                                        Text("Cancel")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        if !newHabitName.isEmpty {
                                            habitConfig.addHabit(name: newHabitName, emoji: newHabitEmoji)
                                            newHabitName = ""
                                            newHabitEmoji = ""
                                            showingHabitInput = false
                                        }
                                    }) {
                                        Text("Add")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.green.opacity(0.4))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        Text("Tap to delete • Drag to reorder")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        
                        VStack(spacing: 12) {
                            ForEach(habitConfig.habits) { habit in
                                HStack(spacing: 12) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.3))
                                    
                                    if !habit.emoji.isEmpty {
                                        Text(habit.emoji)
                                            .font(.system(size: 24))
                                    }
                                    
                                    Text(habit.name)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { habit.isVisible },
                                        set: { _ in habitConfig.toggleVisibility(for: habit.id) }
                                    ))
                                    .labelsHidden()
                                    .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if !habit.isSystem {
                                        habitToDelete = habit
                                        showDeleteConfirmation = true
                                    }
                                }
                            }
                            .onMove { from, to in
                                habitConfig.moveHabit(from: from, to: to)
                            }
                        }
                    }
                }
                
                // Daily Reminders Section
                WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Daily Reminders")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                        }
                        
                        Text("Get reminded to complete your Simran and Sehaj Paath practice throughout the day until you've marked them as done.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Toggle(isOn: $dailyRemindersEnabled) {
                            Text("Enable Daily Reminders")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .onChange(of: dailyRemindersEnabled) { enabled in
                            if enabled {
                                requestNotificationPermission()
                            } else {
                                cancelDailyReminders()
                            }
                            saveReminderSettings()
                        }
                        
                        if dailyRemindersEnabled {
                            VStack(spacing: 16) {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                VStack(spacing: 12) {
                                    Text("How many times per day?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 12) {
                                        ForEach(1...3, id: \.self) { count in
                                            Button(action: {
                                                reminderFrequency = count
                                                saveReminderSettings()
                                                scheduleDailyReminders()
                                            }) {
                                                Text("\(count)x")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(reminderFrequency == count ? .white : .white.opacity(0.6))
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(reminderFrequency == count ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3) : Color.white.opacity(0.1))
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(reminderFrequency == count ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color.white.opacity(0.2), lineWidth: 1.5)
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                if reminderFrequency >= 1 {
                                    VStack(spacing: 8) {
                                        Text("First Reminder")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                        DatePicker("", selection: $reminderTime1, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                            .onChange(of: reminderTime1) { _ in
                                                saveReminderSettings()
                                                scheduleDailyReminders()
                                            }
                                    }
                                }
                                
                                if reminderFrequency >= 2 {
                                    VStack(spacing: 8) {
                                        Text("Second Reminder")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                        DatePicker("", selection: $reminderTime2, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                            .onChange(of: reminderTime2) { _ in
                                                saveReminderSettings()
                                                scheduleDailyReminders()
                                            }
                                    }
                                }
                                
                                if reminderFrequency >= 3 {
                                    VStack(spacing: 8) {
                                        Text("Third Reminder")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                        DatePicker("", selection: $reminderTime3, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .colorScheme(.dark)
                                            .onChange(of: reminderTime3) { _ in
                                                saveReminderSettings()
                                                scheduleDailyReminders()
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Quote Notifications Section
                WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Quote Notifications")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                        }
                        
                        Text("Receive selected quotes from your saved bank at different times of the day, to keep you on top of your game.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Toggle(isOn: $quoteNotificationsEnabled) {
                            Text("Enable Quote Notifications")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .onChange(of: quoteNotificationsEnabled) { enabled in
                            if enabled {
                                requestNotificationPermission()
                            } else {
                                cancelQuoteNotifications()
                            }
                            saveQuoteNotificationSettings()
                        }
                        
                        if quoteNotificationsEnabled {
                            VStack(spacing: 12) {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                Text("When would you like to receive quotes?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Toggle(isOn: $morningQuotesEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Morning")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("8:00 AM - 12:00 PM")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                                .onChange(of: morningQuotesEnabled) { _ in
                                    saveQuoteNotificationSettings()
                                    scheduleQuoteNotifications()
                                }
                                
                                Toggle(isOn: $afternoonQuotesEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Afternoon")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("12:00 PM - 5:00 PM")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                                .onChange(of: afternoonQuotesEnabled) { _ in
                                    saveQuoteNotificationSettings()
                                    scheduleQuoteNotifications()
                                }
                                
                                Toggle(isOn: $nightQuotesEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Night")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("6:00 PM - 9:00 PM")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                                .onChange(of: nightQuotesEnabled) { _ in
                                    saveQuoteNotificationSettings()
                                    scheduleQuoteNotifications()
                                }
                            }
                        }
                    }
                }
                
                // Quote Bank Section
                WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Quote Bank")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                            
                            Button(action: {
                                showingQuoteInput.toggle()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            }
                        }
                        
                        if showingQuoteInput {
                            VStack(spacing: 12) {
                                TextField("Enter a quote...", text: $newQuote, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .lineLimit(3...6)
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showingQuoteInput = false
                                        newQuote = ""
                                    }) {
                                        Text("Cancel")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        if !newQuote.isEmpty {
                                            quotes.append(newQuote)
                                            saveQuotes()
                                            newQuote = ""
                                            showingQuoteInput = false
                                        }
                                    }) {
                                        Text("Add")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.green.opacity(0.4))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        if quotes.isEmpty {
                            Text("No quotes yet. Add your first inspirational quote!")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(quotes.enumerated()), id: \.offset) { index, quote in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\"\(quote)\"")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            quotes.remove(at: index)
                                            saveQuotes()
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 16))
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .onAppear {
            loadQuotes()
            loadReminderSettings()
            loadQuoteNotificationSettings()
            checkNotificationStatus()
        }
        .alert("Delete Habit", isPresented: $showDeleteConfirmation, presenting: habitToDelete) { habit in
            Button("Cancel", role: .cancel) {
                habitToDelete = nil
            }
            Button("Delete", role: .destructive) {
                habitConfig.deleteHabit(id: habit.id)
                habitToDelete = nil
            }
        } message: { habit in
            Text("Are you sure you want to delete '\(habit.name)'?")
        }
    }
    
    // MARK: - Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    if self.dailyRemindersEnabled {
                        self.scheduleDailyReminders()
                    }
                    if self.quoteNotificationsEnabled {
                        self.scheduleQuoteNotifications()
                    }
                }
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // Don't override user settings, just check permission
            }
        }
    }
    
    // MARK: - Daily Reminders
    func scheduleDailyReminders() {
        // Cancel existing daily reminders
        let reminderIds = ["dailyReminder1", "dailyReminder2", "dailyReminder3"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIds)
        
        guard dailyRemindersEnabled else { return }
        
        let times = [reminderTime1, reminderTime2, reminderTime3]
        let calendar = Calendar.current
        
        for i in 0..<reminderFrequency {
            let content = UNMutableNotificationContent()
            content.title = "Simran & Sehaj Paath Reminder"
            content.body = "Don't forget to complete your daily practice! 🙏"
            content.sound = .default
            
            let components = calendar.dateComponents([.hour, .minute], from: times[i])
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let request = UNNotificationRequest(identifier: "dailyReminder\(i + 1)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelDailyReminders() {
        let reminderIds = ["dailyReminder1", "dailyReminder2", "dailyReminder3"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderIds)
    }
    
    func saveReminderSettings() {
        UserDefaults.standard.set(dailyRemindersEnabled, forKey: "dailyRemindersEnabled")
        UserDefaults.standard.set(reminderFrequency, forKey: "reminderFrequency")
        UserDefaults.standard.set(reminderTime1, forKey: "reminderTime1")
        UserDefaults.standard.set(reminderTime2, forKey: "reminderTime2")
        UserDefaults.standard.set(reminderTime3, forKey: "reminderTime3")
    }
    
    func loadReminderSettings() {
        dailyRemindersEnabled = UserDefaults.standard.bool(forKey: "dailyRemindersEnabled")
        reminderFrequency = UserDefaults.standard.integer(forKey: "reminderFrequency")
        if reminderFrequency == 0 { reminderFrequency = 1 }
        
        if let time1 = UserDefaults.standard.object(forKey: "reminderTime1") as? Date {
            reminderTime1 = time1
        } else {
            reminderTime1 = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        }
        
        if let time2 = UserDefaults.standard.object(forKey: "reminderTime2") as? Date {
            reminderTime2 = time2
        } else {
            reminderTime2 = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
        }
        
        if let time3 = UserDefaults.standard.object(forKey: "reminderTime3") as? Date {
            reminderTime3 = time3
        } else {
            reminderTime3 = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
    
    // MARK: - Quote Notifications
    func scheduleQuoteNotifications() {
        // Cancel existing quote notifications
        let quoteIds = ["morningQuote", "afternoonQuote", "nightQuote"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: quoteIds)
        
        guard quoteNotificationsEnabled && !quotes.isEmpty else { return }
        
        if morningQuotesEnabled {
            scheduleQuoteNotification(identifier: "morningQuote", hour: 10, minute: 0)
        }
        
        if afternoonQuotesEnabled {
            scheduleQuoteNotification(identifier: "afternoonQuote", hour: 14, minute: 30)
        }
        
        if nightQuotesEnabled {
            scheduleQuoteNotification(identifier: "nightQuote", hour: 19, minute: 30)
        }
    }
    
    func scheduleQuoteNotification(identifier: String, hour: Int, minute: Int) {
        guard !quotes.isEmpty else { return }
        
        let randomQuote = quotes.randomElement() ?? "Stay inspired!"
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Inspiration"
        content.body = randomQuote
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelQuoteNotifications() {
        let quoteIds = ["morningQuote", "afternoonQuote", "nightQuote"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: quoteIds)
    }
    
    func saveQuoteNotificationSettings() {
        UserDefaults.standard.set(quoteNotificationsEnabled, forKey: "quoteNotificationsEnabled")
        UserDefaults.standard.set(morningQuotesEnabled, forKey: "morningQuotesEnabled")
        UserDefaults.standard.set(afternoonQuotesEnabled, forKey: "afternoonQuotesEnabled")
        UserDefaults.standard.set(nightQuotesEnabled, forKey: "nightQuotesEnabled")
    }
    
    func loadQuoteNotificationSettings() {
        quoteNotificationsEnabled = UserDefaults.standard.bool(forKey: "quoteNotificationsEnabled")
        morningQuotesEnabled = UserDefaults.standard.bool(forKey: "morningQuotesEnabled")
        afternoonQuotesEnabled = UserDefaults.standard.bool(forKey: "afternoonQuotesEnabled")
        nightQuotesEnabled = UserDefaults.standard.bool(forKey: "nightQuotesEnabled")
    }
    
    // MARK: - Quote Bank
    func saveQuotes() {
        UserDefaults.standard.set(quotes, forKey: "quote_bank")
        if quoteNotificationsEnabled {
            scheduleQuoteNotifications()
        }
    }
    
    func loadQuotes() {
        if let saved = UserDefaults.standard.array(forKey: "quote_bank") as? [String] {
            quotes = saved
        }
    }
}

struct CalendarGridView: View {
    let simranTracker: HabitTracker
    let paathTracker: SehajPaathTracker
    @Binding var selectedDate: Date?
    let displayMonth: Date
    
    var body: some View {
        VStack(spacing: 8) {
            let calendar = Calendar.current
            let month = calendar.component(.month, from: displayMonth)
            let year = calendar.component(.year, from: displayMonth)
            
            let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
            let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
            
            let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            
            HStack(spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            let totalCells = daysInMonth + (firstWeekday - 1)
            let rows = Int(ceil(Double(totalCells) / 7.0))
            
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        let day = index - (firstWeekday - 2)
                        
                        if day > 0 && day <= daysInMonth {
                            let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                            let simranDone = simranTracker.isCompleted(on: date)
                            let paathDone = paathTracker.didComplete(on: date)
                            let bothDone = simranDone && paathDone
                            
                            Button(action: {
                                selectedDate = date
                            }) {
                                VStack(spacing: 2) {
                                    Text("\(day)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Circle()
                                        .fill(bothDone ? Color.green : (simranDone || paathDone) ? Color.yellow.opacity(0.6) : Color.white.opacity(0.1))
                                        .frame(width: 6, height: 6)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                    }
                }
            }
        }
    }
}

struct WidgetCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

class HabitTracker: ObservableObject {
    @Published var isCompletedToday: Bool = false
    @Published var hasAnsweredToday: Bool = false
    @Published var currentStreak: Int = 0
    @Published var last7Days: [DayRecord] = []
    
    private let defaults = UserDefaults.standard
    private let prefix: String
    
    init(prefix: String = "simran") {
        self.prefix = prefix
        loadToday()
        calculateStreak()
        loadLast7Days()
    }
    
    func markToday(completed: Bool) {
        let today = dateKey(for: Date())
        defaults.set(completed, forKey: today)
        
        // Also save to shared UserDefaults for widget
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
        sharedDefaults?.set(completed, forKey: today)
        
        isCompletedToday = completed
        hasAnsweredToday = true
        calculateStreak()
        loadLast7Days()
        
        updateLiveActivity()
    }
    
    func clearToday() {
        let today = dateKey(for: Date())
        defaults.removeObject(forKey: today)
        
        // Also clear from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
        sharedDefaults?.removeObject(forKey: today)
        
        isCompletedToday = false
        hasAnsweredToday = false
        calculateStreak()
        loadLast7Days()
        
        updateLiveActivity()
    }
    
    func updateLiveActivity() {
        // Update or start live activity if both tasks aren't complete
        if #available(iOS 16.2, *) {
            let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
            let today = dateKey(for: Date())
            let simranDone = sharedDefaults?.object(forKey: today) as? Bool ?? false
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayKey = dateFormatter.string(from: Date())
            let paathAngs = sharedDefaults?.integer(forKey: "paath_angs_\(todayKey)") ?? 0
            
            if simranDone && paathAngs > 0 {
                // Both complete, end activity
                Task {
                    for activity in Activity<DayaLiveActivityAttributes>.activities {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                }
            } else {
                // Update or create activity
                let attributes = DayaLiveActivityAttributes()
                let contentState = DayaLiveActivityAttributes.ContentState(
                    simranDone: simranDone,
                    paathAngs: paathAngs
                )
                
                Task {
                    if let activity = Activity<DayaLiveActivityAttributes>.activities.first {
                        await activity.update(using: contentState)
                    } else {
                        do {
                            _ = try Activity.request(
                                attributes: attributes,
                                contentState: contentState,
                                pushType: nil
                            )
                        } catch {
                            print("Error starting activity: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func isCompleted(on date: Date) -> Bool {
        let key = dateKey(for: date)
        return defaults.object(forKey: key) as? Bool ?? false
    }
    
    private func loadToday() {
        let today = dateKey(for: Date())
        if let value = defaults.object(forKey: today) as? Bool {
            isCompletedToday = value
            hasAnsweredToday = true
        }
    }
    
    private func calculateStreak() {
        var streak = 0
        var currentDate = Date()
        
        while true {
            let key = dateKey(for: currentDate)
            if let completed = defaults.object(forKey: key) as? Bool, completed {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        currentStreak = streak
    }
    
    private func loadLast7Days() {
        var days: [DayRecord] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Find the most recent Sunday
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = (weekday - 1) % 7
        let mostRecentSunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today)!
        
        // Create 7 days starting from Sunday
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: mostRecentSunday)!
            let key = dateKey(for: date)
            let completed = defaults.object(forKey: key) as? Bool
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayLabel = formatter.string(from: date)
            days.append(DayRecord(date: date, completed: completed, dayLabel: dayLabel))
        }
        
        last7Days = days
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(prefix)_" + formatter.string(from: date)
    }
    
    private func dayLabel(for date: Date, daysAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    func markHistoricalDate(_ date: Date, completed: Bool) {
        let key = dateKey(for: date)
        defaults.set(completed, forKey: key)
        
        // Also save to shared UserDefaults for widget
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
        sharedDefaults?.set(completed, forKey: key)
        
        calculateStreak()
        loadLast7Days()
    }
    
    func clearHistoricalDate(_ date: Date) {
        let key = dateKey(for: date)
        defaults.removeObject(forKey: key)
        
        // Also clear from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
        sharedDefaults?.removeObject(forKey: key)
        
        calculateStreak()
        loadLast7Days()
    }
}

class SehajPaathTracker: ObservableObject {
    @Published var targetDate: Date? {
        didSet {
            if let date = targetDate {
                defaults.set(date, forKey: "paath_target_date")
            } else {
                defaults.removeObject(forKey: "paath_target_date")
            }
            updateProgress()
        }
    }
    
    @Published var dailyAverage: Double = 0
    @Published var estimatedFinishDate: String = "—"
    @Published var requiredDailyAngs: Double?
    
    private let defaults = UserDefaults.standard
    private let totalAngs = 1430
    private let startDateKey = "paath_start_date"
    
    var currentAng: Int {
        return getTotalAngsRead()
    }
    
    var formattedTargetDate: String {
        guard let date = targetDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    init() {
        if let savedDate = defaults.object(forKey: "paath_target_date") as? Date {
            self.targetDate = savedDate
        }
        
        if defaults.object(forKey: startDateKey) == nil {
            defaults.set(Date(), forKey: startDateKey)
        }
        
        updateProgress()
    }
    
    func setAngsForToday(_ angs: Int) {
        let key = "paath_angs_" + dateKey(for: Date())
        defaults.set(angs, forKey: key)
        
        // Also save to shared UserDefaults for widget
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
        sharedDefaults?.set(angs, forKey: key)
        
        objectWillChange.send()
        updateProgress()
        markTodayIfChanged()
        updateLiveActivity()
    }
    
    func updateLiveActivity() {
        if #available(iOS 16.2, *) {
            let sharedDefaults = UserDefaults(suiteName: "group.com.daya.app")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayKey = dateFormatter.string(from: Date())
            let simranDone = sharedDefaults?.object(forKey: "simran_\(todayKey)") as? Bool ?? false
            let paathAngs = sharedDefaults?.integer(forKey: "paath_angs_\(todayKey)") ?? 0
            
            if simranDone && paathAngs > 0 {
                // Both complete, end activity
                Task {
                    for activity in Activity<DayaLiveActivityAttributes>.activities {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                }
            } else {
                // Update or create activity
                let attributes = DayaLiveActivityAttributes()
                let contentState = DayaLiveActivityAttributes.ContentState(
                    simranDone: simranDone,
                    paathAngs: paathAngs
                )
                
                Task {
                    if let activity = Activity<DayaLiveActivityAttributes>.activities.first {
                        await activity.update(using: contentState)
                    } else {
                        do {
                            _ = try Activity.request(
                                attributes: attributes,
                                contentState: contentState,
                                pushType: nil
                            )
                        } catch {
                            print("Error starting activity: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func setAngsForDate(_ angs: Int, date: Date) {
        let key = "paath_angs_" + dateKey(for: date)
        defaults.set(angs, forKey: key)
        objectWillChange.send()
        updateProgress()
    }
    
    func getAngsForDate(_ date: Date) -> Int {
        let key = "paath_angs_" + dateKey(for: date)
        return defaults.integer(forKey: key)
    }
    
    func getTotalAngsRead() -> Int {
        guard let startDate = defaults.object(forKey: startDateKey) as? Date else { return 0 }
        let calendar = Calendar.current
        let today = Date()
        let daysDiff = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        
        var total = 0
        for i in 0...daysDiff {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                total += getAngsForDate(date)
            }
        }
        return total
    }
    
    private func updateProgress() {
        guard let startDate = defaults.object(forKey: startDateKey) as? Date else { return }
        let daysSinceStart = max(1, Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 1)
        
        let total = getTotalAngsRead()
        dailyAverage = Double(total) / Double(daysSinceStart)
        
        let remainingAngs = totalAngs - total
        if dailyAverage > 0 {
            let daysRemaining = Int(ceil(Double(remainingAngs) / dailyAverage))
            if let finishDate = Calendar.current.date(byAdding: .day, value: daysRemaining, to: Date()) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                estimatedFinishDate = formatter.string(from: finishDate)
            }
        }
        
        if let target = targetDate {
            let daysUntilTarget = max(1, Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 1)
            requiredDailyAngs = Double(remainingAngs) / Double(daysUntilTarget)
        } else {
            requiredDailyAngs = nil
        }
    }
    
    private func markTodayIfChanged() {
        let angsToday = getAngsForDate(Date())
        if angsToday > 0 {
            defaults.set(true, forKey: "paath_completed_" + dateKey(for: Date()))
        }
    }
    
    func didComplete(on date: Date) -> Bool {
        let key = "paath_completed_" + dateKey(for: date)
        return defaults.bool(forKey: key)
    }
    
    func combinedStreak(with simranTracker: HabitTracker) -> Int {
        var streak = 0
        var currentDate = Date()
        
        while true {
            if didComplete(on: currentDate) && simranTracker.isCompleted(on: currentDate) {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    func last7DaysCombined(with simranTracker: HabitTracker) -> [CombinedDayRecord] {
        var days: [CombinedDayRecord] = []
        let calendar = Calendar.current
        
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let bothCompleted = didComplete(on: date) && simranTracker.isCompleted(on: date)
            let dayLabel = dayLabel(for: date, daysAgo: i)
            days.append(CombinedDayRecord(date: date, bothCompleted: bothCompleted, dayLabel: dayLabel))
        }
        
        return days
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func dayLabel(for date: Date, daysAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    func last7DaysProgress() -> [PaathDayRecord] {
        var days: [PaathDayRecord] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Find the most recent Sunday
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = (weekday - 1) % 7
        let mostRecentSunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today)!
        
        // Create 7 days starting from Sunday
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: mostRecentSunday)!
            let completed = didComplete(on: date)
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayLabel = formatter.string(from: date)
            days.append(PaathDayRecord(date: date, completed: completed, dayLabel: dayLabel))
        }
        
        return days
    }
    
    var angsReadToday: Int {
        return getAngsForDate(Date())
    }
    
    var percentComplete: Double {
        return (Double(currentAng) / Double(totalAngs)) * 100
    }
}

struct DayRecord {
    let date: Date
    let completed: Bool?
    let dayLabel: String
}

struct PaathDayRecord {
    let date: Date
    let completed: Bool
    let dayLabel: String
}

struct CombinedDayRecord {
    let date: Date
    let bothCompleted: Bool
    let dayLabel: String
}
