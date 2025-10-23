import SwiftUI
import ActivityKit
import UserNotifications
import WidgetKit

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
    
    static let morningSimran = Habit(id: "morning_simran", name: "Simran", emoji: "🏆", isVisible: true, isSystem: true)
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
            
            // Ensure Nitnem is always present
            if !habits.contains(where: { $0.id == "nitnem" }) {
                let nitnem = Habit(id: "nitnem", name: "Nitnem", emoji: "📿", isVisible: true, isSystem: false)
                habits.insert(nitnem, at: 0) // Insert at the beginning
                saveHabits()
            }
        } else {
            // Add Nitnem as a default custom habit
            let nitnem = Habit(id: "nitnem", name: "Nitnem", emoji: "📿", isVisible: true, isSystem: false)
            habits = [nitnem, .morningSimran, .sehajPaath]
            saveHabits()
        }
    }
    
    func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            defaults.set(encoded, forKey: key)
            
            // Also save to shared defaults for widget access
            let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
            sharedDefaults?.set(encoded, forKey: key)
            
            // Refresh widgets
            WidgetCenter.shared.reloadAllTimelines()
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

class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "has_completed_onboarding")
        }
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

struct ContentView: View {
    @StateObject private var simranTracker = HabitTracker()
    @StateObject private var paathTracker = SehajPaathTracker()
    @StateObject private var habitConfig = HabitConfig()
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var selectedTab = 0
    
    var body: some View {
        if !onboardingManager.hasCompletedOnboarding {
            OnboardingView(onboardingManager: onboardingManager, habitConfig: habitConfig)
        } else {
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
                
                // Content
                TabView(selection: $selectedTab) {
                    TodayView(simranTracker: simranTracker, paathTracker: paathTracker, habitConfig: habitConfig)
                        .tag(0)
                    
                    CalendarTabView(simranTracker: simranTracker, paathTracker: paathTracker, habitConfig: habitConfig)
                        .tag(1)
                    
                    SettingsView(habitConfig: habitConfig, onboardingManager: onboardingManager)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Floating tab bar overlay
                VStack {
                    Spacer()
                    
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
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                }
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
    @State private var showAngsPopup = false
    
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
                
                // Custom Habits (including Nitnem)
                ForEach(habitConfig.habits.filter { !$0.isSystem && $0.isVisible }) { habit in
                    CustomHabitWidget(habit: habit, tracker: HabitTracker(prefix: habit.id))
                }
                
                // Simran Widget
                if habitConfig.isVisible("morning_simran") {
                    WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Simran")
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
                            Text("Complete simran by attending sangat at a Gurdwara or doing at least 30 minutes of meditation on your own.")
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
                        
                        VStack(spacing: 12) {
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
                        showAngsPopup = true
                    }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .sheet(isPresented: $showAngsPopup) {
            AngsUpdatePopup(paathTracker: paathTracker)
        }
    }
}

struct AngsUpdatePopup: View {
    @ObservedObject var paathTracker: SehajPaathTracker
    @Environment(\.dismiss) private var dismiss
    @State private var dailyAngsInput: String = ""
    @State private var currentAngInput: String = ""
    @State private var isEditingDaily = true
    @State private var targetDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Update Progress")
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Content
            VStack(spacing: 24) {
                // Current Progress Display
                VStack(spacing: 8) {
                    Text("Current Progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(paathTracker.currentAng) / 1430")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    
                    Text("\(Int(paathTracker.percentComplete))% Complete")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Target Date Section
                VStack(spacing: 16) {
                    Text("Target Finish Date")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    DatePicker("", selection: $targetDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                        .accentColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .onAppear {
                            targetDate = paathTracker.targetDate ?? Date()
                        }
                        .onChange(of: targetDate) { newValue in
                            paathTracker.targetDate = newValue
                        }
                }
                
                // Input Section
                VStack(spacing: 16) {
                    Text("How many angs did you read today?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    TextField("0", text: $dailyAngsInput)
                        .keyboardType(.numberPad)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .onAppear {
                            dailyAngsInput = "\(paathTracker.angsReadToday)"
                        }
                        .onChange(of: dailyAngsInput) { newValue in
                            if let angs = Int(newValue), angs >= 0 {
                                paathTracker.setAngsForToday(angs)
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Done Button
            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.8, green: 0.67, blue: 0.0))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.08, blue: 0.15))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct CustomHabitWidget: View {
    let habit: Habit
    @ObservedObject var tracker: HabitTracker
    @State private var showHabitInfo = false
    
    var body: some View {
        WidgetCard {
            VStack(spacing: 16) {
                HStack {
                    Text(habit.name)
                        .font(.custom("Georgia-Bold", size: 22))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    
                    Button(action: {
                        showHabitInfo.toggle()
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                
                if showHabitInfo {
                    Text("Track your daily progress for this habit. Mark as completed when you've finished it for the day.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        if tracker.isCompletedToday {
                            tracker.clearToday()
                        } else {
                            tracker.markToday(completed: true)
                        }
                    }) {
                        Text("🏆")
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
                            habitConfig: habitConfig,
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
                            
                            VStack(spacing: 16) {
                                // Display all visible habits
                                ForEach(habitConfig.habits.filter { $0.isVisible }) { habit in
                                    if habit.id == "sehaj_paath" {
                                        // Sehaj Paath with angs count
                                        HStack {
                                            Text(habit.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(paathTracker.getAngsForDate(selected)) angs")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(red: 1.0, green: 0.95, blue: 0.85))
                                        }
                                    } else {
                                        // All other habits with checkmark
                                        HStack {
                                            Text(habit.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                            Spacer()
                                            let tracker = habit.isSystem ? simranTracker : HabitTracker(prefix: habit.id)
                                            Text(tracker.isCompleted(on: selected) ? "✅" : "❌")
                                                .font(.system(size: 20))
                                        }
                                    }
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
                                habitConfig: habitConfig,
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
        .onAppear {
            // Refresh tracker states when calendar tab becomes visible
            simranTracker.refreshData()
            paathTracker.refreshData()
            
            // Set current day as selected by default
            if selectedDate == nil {
                selectedDate = Date()
            }
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
    @ObservedObject var habitConfig: HabitConfig
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
                // All Habits (excluding Sehaj Paath)
                ForEach(habitConfig.habits.filter { $0.isVisible && $0.id != "sehaj_paath" }) { habit in
                    VStack(spacing: 16) {
                        Text(habit.name)
                            .font(.custom("Georgia-Bold", size: 20))
                            .foregroundColor(.white)
                        
                        HabitEditButtons(habit: habit, date: date, simranTracker: simranTracker)
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
            
            // Done Button
            Button(action: {
                if let angs = Int(historicalAngsInput) {
                    paathTracker.setAngsForDate(angs, date: date)
                }
                
                isPresented = false
            }) {
                Text("Done")
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

struct HabitEditButtons: View {
    let habit: Habit
    let date: Date
    @ObservedObject var simranTracker: HabitTracker
    @State private var habitStatus: Bool?
    
    var body: some View {
        let tracker = habit.isSystem ? simranTracker : HabitTracker(prefix: habit.id)
        
        HStack(spacing: 20) {
            Button(action: {
                tracker.markHistoricalDate(date, completed: true)
                habitStatus = true
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
                .background(tracker.isCompleted(on: date) ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tracker.isCompleted(on: date) ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                )
            }
            
            Button(action: {
                tracker.markHistoricalDate(date, completed: false)
                habitStatus = false
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
                .background(!tracker.isCompleted(on: date) && habitStatus == false ? Color.red.opacity(0.3) : Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(!tracker.isCompleted(on: date) && habitStatus == false ? Color.red : Color.white.opacity(0.2), lineWidth: 2)
                )
            }
            
            Button(action: {
                tracker.clearHistoricalDate(date)
                habitStatus = nil
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
                .background(!tracker.isCompleted(on: date) && habitStatus == nil ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(!tracker.isCompleted(on: date) && habitStatus == nil ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 2)
                )
            }
        }
        .onAppear {
            habitStatus = tracker.isCompleted(on: date) ? true : nil
        }
    }
}

struct SettingsView: View {
    @ObservedObject var habitConfig: HabitConfig
    @ObservedObject var onboardingManager: OnboardingManager
    
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
    @State private var showResetAllConfirmation = false
    @State private var showResetPaathConfirmation = false
    
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
                
                // Foundation Message
                WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("✨ About Daya")
                                .font(.custom("Georgia-Bold", size: 20))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daya is a non-profit project that will always be free.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                            
                            Text("Built by Kordova Tek Foundation - Technology in Service of Humanity")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                                .italic()
                        }
                        
                        Button(action: {
                            sendFeatureRequest()
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16))
                                Text("Send Feature Request")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .padding(16)
                            .background(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button(action: {
                            shareWithFriend()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 16))
                                Text("Share with Friend")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .padding(16)
                            .background(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                
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
                                    
                                    if habit.id == "sehaj_paath" {
                                        Text(habit.emoji)
                                            .font(.system(size: 24))
                                    } else {
                                        Text("🏆")
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
                        
                        Text("Get reminded to complete your habits throughout the day until you've marked them as done.")
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
                                // Auto-fill beautiful quotes if none exist
                                if quotes.isEmpty {
                                    autoFillQuotes()
                                }
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
                
                // Quote Bank Section (only show if quote notifications are enabled)
                if quoteNotificationsEnabled {
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
                }
                
                // Reset Options
                WidgetCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Reset Data")
                                .font(.custom("Georgia-Bold", size: 22))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                showResetAllConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    Text("Reset All Data")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            Button(action: {
                                showResetPaathConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    Text("Reset Sehaj Paath Progress")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), lineWidth: 1)
                                )
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
        .alert("Reset All Data", isPresented: $showResetAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset All", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will reset all habits, Sehaj Paath progress, and settings. This action cannot be undone.")
        }
        .alert("Reset Sehaj Paath Progress", isPresented: $showResetPaathConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Progress", role: .destructive) {
                resetSehajPaathProgress()
            }
        } message: {
            Text("This will reset all Sehaj Paath progress and start from the beginning. This action cannot be undone.")
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
        
        // Get enabled habits for dynamic messaging
        let enabledHabits = habitConfig.habits.filter { $0.isVisible }
        let habitNames = enabledHabits.map { $0.name }
        
        for i in 0..<reminderFrequency {
            let content = UNMutableNotificationContent()
            
            if habitNames.count == 1 {
                content.title = "\(habitNames[0]) Reminder"
                content.body = "Don't forget to complete your \(habitNames[0].lowercased()) today! 🙏"
            } else if habitNames.count == 2 {
                content.title = "Daily Habits Reminder"
                content.body = "Don't forget to complete your \(habitNames[0]) and \(habitNames[1]) today! 🙏"
            } else if habitNames.count > 2 {
                content.title = "Daily Habits Reminder"
                content.body = "Don't forget to complete your habits today! 🙏"
            } else {
                content.title = "Daily Habits Reminder"
                content.body = "Don't forget to complete your daily practice! 🙏"
            }
            
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
    
    func resetAllData() {
        // Reset all UserDefaults
        let defaults = UserDefaults.standard
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        
        // Get all keys and remove them
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys {
            defaults.removeObject(forKey: key)
        }
        
        // Reset shared defaults
        if let sharedKeys = sharedDefaults?.dictionaryRepresentation().keys {
            for key in sharedKeys {
                sharedDefaults?.removeObject(forKey: key)
            }
        }
        
        // Reset habit config to defaults
        let nitnem = Habit(id: "nitnem", name: "Nitnem", emoji: "📿", isVisible: true, isSystem: false)
        habitConfig.habits = [nitnem, .morningSimran, .sehajPaath]
        habitConfig.saveHabits()
        
        // Cancel all notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Reset onboarding state
        onboardingManager.resetOnboarding()
    }
    
    func resetSehajPaathProgress() {
        let defaults = UserDefaults.standard
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        
        // Remove all Sehaj Paath related keys
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("paath_") {
                defaults.removeObject(forKey: key)
            }
        }
        
        // Remove from shared defaults
        if let sharedKeys = sharedDefaults?.dictionaryRepresentation().keys {
            for key in sharedKeys {
                if key.hasPrefix("paath_") {
                    sharedDefaults?.removeObject(forKey: key)
                }
            }
        }
        
        // Reset start date to today
        defaults.set(Date(), forKey: "paath_start_date")
    }
    
    func sendFeatureRequest() {
        let email = "foundation@kordovatek.com"
        let subject = "Feature Request / Daya"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(email)?subject=\(encodedSubject)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func shareWithFriend() {
        let message = "Try Daya — a beautiful habit tracker to build daily discipline with compassion. Download: https://apps.apple.com/app/daya"
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "sms:&body=\(encodedMessage)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func autoFillQuotes() {
        let beautifulQuotes = [
            "The body is a guest house; the soul will not stay forever.",
            "What you think, you become.",
            "Live in gratitude."
        ]
        
        quotes = beautifulQuotes
        saveQuotes()
    }
}

// MARK: - Onboarding Views

struct OnboardingView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @ObservedObject var habitConfig: HabitConfig
    @State private var currentPage = 0
    @State private var selectedHabits: Set<String> = ["nitnem", "morning_simran", "sehaj_paath"]
    @State private var customHabitName = ""
    @State private var remindersEnabled = false
    @State private var quotesEnabled = false
    @State private var notificationPermissionGranted = false
    
    let totalPages = 4
    
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
            
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingWelcomePage()
                    .tag(0)
                
                // Page 2: Habits
                OnboardingHabitsPage(
                    selectedHabits: $selectedHabits,
                    customHabitName: $customHabitName,
                    habitConfig: habitConfig
                )
                .tag(1)
                
                // Page 3: Reminders
                OnboardingRemindersPage(
                    remindersEnabled: $remindersEnabled,
                    notificationPermissionGranted: $notificationPermissionGranted
                )
                .tag(2)
                
                // Page 4: Quotes
                OnboardingQuotesPage(
                    quotesEnabled: $quotesEnabled,
                    notificationPermissionGranted: $notificationPermissionGranted
                )
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            VStack {
                Spacer()
                
                // Continue/Finish Button
                Button(action: {
                    if currentPage < totalPages - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage < totalPages - 1 ? "Continue" : "Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.8, green: 0.67, blue: 0.0))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
    
    func completeOnboarding() {
        // Apply selected habits
        var newHabits: [Habit] = []
        
        if selectedHabits.contains("nitnem") {
            newHabits.append(Habit(id: "nitnem", name: "Nitnem", emoji: "📿", isVisible: true, isSystem: false))
        }
        if selectedHabits.contains("morning_simran") {
            newHabits.append(.morningSimran)
        }
        if selectedHabits.contains("sehaj_paath") {
            newHabits.append(.sehajPaath)
        }
        
        // Add custom habit if provided
        if !customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let customId = "custom_\(UUID().uuidString)"
            newHabits.append(Habit(id: customId, name: customHabitName, emoji: "📿", isVisible: true, isSystem: false))
        }
        
        habitConfig.habits = newHabits
        habitConfig.saveHabits()
        
        // Enable reminders if selected
        if remindersEnabled {
            UserDefaults.standard.set(true, forKey: "daily_reminders_enabled")
        }
        
        // Enable quotes if selected
        if quotesEnabled {
            UserDefaults.standard.set(true, forKey: "quote_notifications_enabled")
            // Auto-fill default quotes
            let beautifulQuotes = [
                "The body is a guest house; the soul will not stay forever.",
                "What you think, you become.",
                "Live in gratitude."
            ]
            if let encoded = try? JSONEncoder().encode(beautifulQuotes) {
                UserDefaults.standard.set(encoded, forKey: "quotes")
            }
        }
        
        onboardingManager.hasCompletedOnboarding = true
    }
}

struct OnboardingWelcomePage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 60)
                
                // App Icon/Logo
                Text("🙏")
                    .font(.system(size: 80))
                
                // App Name
                Text("daya")
                    .font(.custom("Georgia-Bold", size: 48))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                // Mission Statement
                VStack(spacing: 20) {
                    Text("We believe a whole life starts grounded in simplicity - great habits and daya (compassion).")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("In Sikhi, daya means the strength to act with kindness, discipline, and awareness.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("Our goal is to evolve into a companion that keeps you grounded in the present — building good habits, living in daya and love.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Foundation Info
                VStack(spacing: 12) {
                    Text("Daya is a non-profit project that will always be free.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Built by Kordova Tek Foundation")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Text("Technology in Service of Humanity")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .italic()
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

struct OnboardingHabitsPage: View {
    @Binding var selectedHabits: Set<String>
    @Binding var customHabitName: String
    @ObservedObject var habitConfig: HabitConfig
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
                Text("Choose Your Habits")
                    .font(.custom("Georgia-Bold", size: 32))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                Text("Select the daily practices you'd like to track")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    // Nitnem
                    HabitToggleCard(
                        title: "Nitnem",
                        description: "Daily prayers and spiritual practice",
                        isSelected: selectedHabits.contains("nitnem")
                    ) {
                        toggleHabit("nitnem")
                    }
                    
                    // Simran
                    HabitToggleCard(
                        title: "Simran",
                        description: "Meditation and remembrance",
                        isSelected: selectedHabits.contains("morning_simran")
                    ) {
                        toggleHabit("morning_simran")
                    }
                    
                    // Sehaj Paath
                    HabitToggleCard(
                        title: "Sehaj Paath",
                        description: "Reading Sri Guru Granth Sahib Ji",
                        isSelected: selectedHabits.contains("sehaj_paath")
                    ) {
                        toggleHabit("sehaj_paath")
                    }
                    
                    // Custom Habit
                    VStack(spacing: 12) {
                        Text("Add Custom Habit (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Enter habit name", text: $customHabitName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    func toggleHabit(_ habitId: String) {
        if selectedHabits.contains(habitId) {
            selectedHabits.remove(habitId)
        } else {
            selectedHabits.insert(habitId)
        }
    }
}

struct HabitToggleCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text("🏆")
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white.opacity(0.3))
            }
            .padding(16)
            .background(isSelected ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color.white.opacity(0.2), lineWidth: 1.5)
            )
        }
    }
}

struct OnboardingRemindersPage: View {
    @Binding var remindersEnabled: Bool
    @Binding var notificationPermissionGranted: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
                Text("Daily Reminders")
                    .font(.custom("Georgia-Bold", size: 32))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                Text("Stay consistent with gentle reminders")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // Notification Preview
                VStack(spacing: 16) {
                    Text("Preview")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🙏")
                                .font(.system(size: 20))
                            Text("daya")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("now")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Text("Daily Habits Reminder")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Don't forget to complete your habits today! 🙏")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                
                // Enable Toggle
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Reminders")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(notificationPermissionGranted ? "Notifications enabled" : "Tap to enable notifications")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $remindersEnabled)
                            .labelsHidden()
                            .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .disabled(!notificationPermissionGranted)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationPermissionGranted = granted
                if granted {
                    remindersEnabled = true
                }
            }
        }
    }
}

struct OnboardingQuotesPage: View {
    @Binding var quotesEnabled: Bool
    @Binding var notificationPermissionGranted: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
                Text("Inspiring Quotes")
                    .font(.custom("Georgia-Bold", size: 32))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                Text("Receive daily wisdom and inspiration")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // Notification Preview
                VStack(spacing: 16) {
                    Text("Preview")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("✨")
                                .font(.system(size: 20))
                            Text("daya")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("now")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Text("Daily Inspiration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("\"The body is a guest house; the soul will not stay forever.\"")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .italic()
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                
                // Enable Toggle
                Button(action: {
                    if !notificationPermissionGranted {
                        requestNotificationPermission()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Quote Notifications")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(notificationPermissionGranted ? "Notifications enabled" : "Tap to enable notifications")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $quotesEnabled)
                            .labelsHidden()
                            .tint(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .disabled(!notificationPermissionGranted)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                
                Text("You can customize your quote bank later in settings")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationPermissionGranted = granted
                if granted {
                    quotesEnabled = true
                }
            }
        }
    }
}

struct CalendarGridView: View {
    let simranTracker: HabitTracker
    let paathTracker: SehajPaathTracker
    let habitConfig: HabitConfig
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
                            
                            // Check all custom habits
                            let customHabitsDone = habitConfig.habits.filter { !$0.isSystem && $0.isVisible }.map { habit in
                                HabitTracker(prefix: habit.id).isCompleted(on: date)
                            }
                            let allCustomHabitsDone = !customHabitsDone.isEmpty && customHabitsDone.allSatisfy { $0 }
                            
                            let allDone = simranDone && paathDone && allCustomHabitsDone
                            let someDone = simranDone || paathDone || customHabitsDone.contains(true)
                            let isToday = calendar.isDate(date, inSameDayAs: Date())
                            
                            Button(action: {
                                selectedDate = date
                            }) {
                                VStack(spacing: 2) {
                                    Text("\(day)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Circle()
                                        .fill(allDone ? Color.green : someDone ? Color.yellow.opacity(0.6) : Color.white.opacity(0.1))
                                        .frame(width: 6, height: 6)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(isToday ? Color.yellow.opacity(0.3) : Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isToday ? Color.yellow.opacity(0.8) : Color.clear, lineWidth: 2)
                                )
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
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        sharedDefaults?.set(completed, forKey: today)
        
        isCompletedToday = completed
        hasAnsweredToday = true
        calculateStreak()
        loadLast7Days()
        
        updateLiveActivity()
        
        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func clearToday() {
        let today = dateKey(for: Date())
        defaults.removeObject(forKey: today)
        
        // Also clear from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        sharedDefaults?.removeObject(forKey: today)
        
        isCompletedToday = false
        hasAnsweredToday = false
        calculateStreak()
        loadLast7Days()
        
        updateLiveActivity()
        
        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateLiveActivity() {
        // Update or start live activity if both tasks aren't complete
        if #available(iOS 16.2, *) {
            let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
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
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        sharedDefaults?.set(completed, forKey: key)
        
        calculateStreak()
        loadLast7Days()
    }
    
    func clearHistoricalDate(_ date: Date) {
        let key = dateKey(for: date)
        defaults.removeObject(forKey: key)
        
        // Also clear from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        sharedDefaults?.removeObject(forKey: key)
        
        calculateStreak()
        loadLast7Days()
    }
    
    func refreshData() {
        loadToday()
        calculateStreak()
        loadLast7Days()
        objectWillChange.send()
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
        let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
        sharedDefaults?.set(angs, forKey: key)
        
        objectWillChange.send()
        updateProgress()
        markTodayIfChanged()
        updateLiveActivity()
        
        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateLiveActivity() {
        if #available(iOS 16.2, *) {
            let sharedDefaults = UserDefaults(suiteName: "group.com.daya.daya")
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
    
    func refreshData() {
        updateProgress()
        objectWillChange.send()
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
