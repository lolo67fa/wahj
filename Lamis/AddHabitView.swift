import SwiftUI

// Add Habit screen: the user names a new habit, picks an icon and days,
// sets a reminder, a daily goal and a duration, then starts their journey.
struct AddHabitView: View {
    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    // When set, the page edits this habit instead of adding a new one.
    private let editing: Habit?

    @State private var habitName: String
    @State private var selectedIcon: String
    @State private var selectedDays: Set<Int>
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var dailyGoal: Int
    @State private var durationDays: Int

    init(editing: Habit? = nil) {
        self.editing = editing
        _habitName = State(initialValue: editing?.name ?? "")
        _selectedIcon = State(initialValue: editing?.icon ?? "book")
        _selectedDays = State(initialValue: editing?.days ?? Set(0...4))
        _reminderEnabled = State(initialValue: editing?.reminderEnabled ?? true)
        _reminderTime = State(initialValue: editing?.reminderTime
            ?? Calendar.current.date(bySettingHour: 20, minute: 30, second: 0, of: .now) ?? .now)
        _dailyGoal = State(initialValue: editing?.dailyGoal ?? 1)
        _durationDays = State(initialValue: editing?.durationDays ?? 21)
    }

    private let icons = ["book", "waterbottle", "figure.walk", "heart", "clock"]
    // Week starts on Saturday: سبت، أحد، اثنين، ثلاثاء، أربعاء، خميس، جمعة
    private let dayLetters = ["س", "ح", "ن", "ث", "ر", "خ", "ج"]
    // Full names read aloud by VoiceOver.
    private let dayNames = ["السبت", "الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"]
    private let iconNames = ["book": "كتاب", "waterbottle": "ماء", "figure.walk": "مشي",
                             "heart": "قلب", "clock": "ساعة"]

    private var canSave: Bool {
        !habitName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(editing == nil ? "أضف عادة" : "تعديل العادة")
                        .font(.largeTitle).bold()
                        .foregroundStyle(Theme.text)
                        .padding(.bottom, 8)

                    sectionTitle("اسم العادة")
                    TextField("", text: $habitName, prompt: Text("قراءة ١٠ صفحات").foregroundStyle(Theme.text.opacity(0.5)))
                        .padding(16)
                        .foregroundStyle(Theme.text)
                        .tint(Theme.pink)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))

                    sectionTitle("الأيقونة")
                    iconPicker

                    sectionTitle("الأيام")
                    dayPicker

                    sectionTitle("وقت التذكير")
                    reminderRow

                    sectionTitle("عدد المرات في اليوم")
                    counterRow(value: $dailyGoal, range: 1...50) { "\(arabicNumber($0)) مرة" }

                    sectionTitle("المدة (أنت تحددها)")
                    counterRow(value: $durationDays, range: 1...365) { "\(arabicNumber($0)) يوم" }
                }
            }
            .scrollIndicators(.hidden)

            ActionButton(title: editing == nil ? "إبدأ رحلتك" : "حفظ", icon: nil, isPrimary: true, action: saveHabit)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
                .padding(.horizontal, 16)
        }
        .padding()
        .background { StarryBackground() }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Sections

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Theme.text)
            .padding(.top, 8)
    }

    private var iconPicker: some View {
        HStack(spacing: 10) {
            ForEach(icons, id: \.self) { icon in
                let isSelected = selectedIcon == icon
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Theme.pink : Theme.text)
                        .frame(width: 64, height: 64)
                        .background(isSelected ? Theme.cream : Theme.card, in: RoundedRectangle(cornerRadius: 18))
                }
                .accessibilityLabel(iconNames[icon] ?? icon)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var dayPicker: some View {
        HStack(spacing: 8) {
            ForEach(dayLetters.indices, id: \.self) { index in
                let isSelected = selectedDays.contains(index)
                Button {
                    if isSelected { selectedDays.remove(index) } else { selectedDays.insert(index) }
                } label: {
                    Text(dayLetters[index])
                        .font(.headline)
                        .foregroundStyle(isSelected ? Theme.onAccent : Theme.pink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(isSelected ? Theme.pink : Color.clear, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.pink, lineWidth: 1))
                }
                .accessibilityLabel(dayNames[index])
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private var reminderRow: some View {
        HStack {
            Image(systemName: "bell")
                .foregroundStyle(Theme.pink)
            DatePicker("وقت التذكير", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!reminderEnabled)
                .opacity(reminderEnabled ? 1 : 0.4)
            Spacer()
            Toggle("تشغيل التذكير", isOn: $reminderEnabled)
                .labelsHidden()
                .tint(Theme.pink)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
    }

    // A "+  value  −" row used for both the daily goal and the duration.
    private func counterRow(value: Binding<Int>, range: ClosedRange<Int>, label: @escaping (Int) -> String) -> some View {
        HStack {
            Button {
                if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(Theme.onAccent)
                    .frame(width: 48, height: 48)
                    .background(Theme.pink, in: Circle())
            }
            .accessibilityLabel("زيادة")

            Spacer()
            Text(label(value.wrappedValue))
                .font(.title3).bold()
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
            Spacer()

            Button {
                if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Theme.text, lineWidth: 1.5))
            }
            .accessibilityLabel("إنقاص")
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
        .animation(.snappy, value: value.wrappedValue)
    }

    // MARK: - Actions

    private func saveHabit() {
        let name = habitName.trimmingCharacters(in: .whitespaces)

        if var habit = editing {
            // Keep the progress, update the settings.
            habit.name = name
            habit.icon = selectedIcon
            habit.days = selectedDays
            habit.reminderEnabled = reminderEnabled
            habit.reminderTime = reminderTime
            habit.durationDays = durationDays
            habit.dailyGoal = dailyGoal
            store.update(habit)
        } else {
            store.add(Habit(
                name: name,
                icon: selectedIcon,
                days: selectedDays,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                durationDays: durationDays,
                dailyGoal: dailyGoal
            ))
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddHabitView()
    }
    .environment(HabitStore())
}
