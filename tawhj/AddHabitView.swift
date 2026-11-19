//
//  AddHabitView.swift
//  tawhj
//
//  Created by ghala alshreef on 07/06/1448 AH.
//

import SwiftUI

// صفحة إضافة/تعديل العادة: تصميم غلا مع وظائف صفحة لميس
// (عدد المرات في اليوم، وضع التعديل، والحفظ في HabitStore المشترك).
struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitStore.self) private var store

    @AppStorage("selectedStarIndex")
    private var selectedStar = 0

    // بعد أول عادة ينتقل التطبيق من صفحات البداية إلى الصفحات الرئيسية.
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    // عند تمرير عادة، الصفحة تعدّلها بدل إضافة عادة جديدة.
    private let editing: Habit?

    @State private var habitName: String
    @State private var selectedIcon: String

    // أرقام الأيام بترتيب الأسبوع: السبت = ٠ ... الجمعة = ٦ (مثل HabitStore)
    @State private var selectedDays: Set<Int>

    @State private var reminderEnabled: Bool

    @State private var reminderTime: Date

    @State private var dailyGoal: Int
    @State private var duration: Int
    @State private var showTimePicker = false
    @State private var showSavedMessage = false
    @State private var errorMessage = ""
    @State private var showError = false

    @FocusState private var nameFocused: Bool

    init(editing: Habit? = nil) {
        self.editing = editing
        _habitName = State(initialValue: editing?.name ?? "")
        _selectedIcon = State(initialValue: editing?.icon ?? "book")
        _selectedDays = State(initialValue: editing?.days ?? Set(0...4))
        _reminderEnabled = State(initialValue: editing?.reminderEnabled ?? true)
        _reminderTime = State(
            initialValue: editing?.reminderTime
                ?? Calendar.current.date(
                    bySettingHour: 20, minute: 30, second: 0, of: .now
                ) ?? .now
        )
        _dailyGoal = State(initialValue: editing?.dailyGoal ?? 1)
        _duration = State(initialValue: editing?.durationDays ?? 21)
    }

    private let pink = Color(
        red: 242 / 255,
        green: 179 / 255,
        blue: 230 / 255
    )

    private let surface = Color(
        red: 67 / 255,
        green: 42 / 255,
        blue: 82 / 255
    )

    private let rowColor = Color(
        red: 75 / 255,
        green: 47 / 255,
        blue: 92 / 255
    )

    private let borderColor = Color(
        red: 106 / 255,
        green: 74 / 255,
        blue: 124 / 255
    )

    private let icons = [
        "book", "waterbottle", "figure.walk", "heart", "clock"
    ]

    private let dayLabels = ["س", "ح", "ن", "ث", "ر", "خ", "ج"]

    private let dayNames = [
        "السبت", "الأحد", "الاثنين",
        "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"
    ]

    private var canSave: Bool {
        !habitName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty && !selectedDays.isEmpty
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 24) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        nameSection
                        iconSection
                        daysSection

                        reminderSection
                            .padding(.top, 14)

                        dailyGoalSection

                        durationSection
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)

                Button {
                    saveHabit()
                } label: {
                    Text(editing == nil ? "ابدأ رحلتك" : "حفظ")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(
                            Color(
                                red: 51 / 255,
                                green: 32 / 255,
                                blue: 63 / 255
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(pink, in: Capsule())
                        .shadow(
                            color: Color(
                                red: 89 / 255,
                                green: 18 / 255,
                                blue: 88 / 255
                            ),
                            radius: 0,
                            y: 5
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.55)
                .padding(.horizontal, 10)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
        }
        .foregroundStyle(Color(red: 1, green: 0.957, blue: 0.992))
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showTimePicker) {
            timePickerSheet
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("تم حفظ عادتك", isPresented: $showSavedMessage) {
            Button("تمام") {
                hasCompletedOnboarding = true
                dismiss()
            }
        } message: {
            Text("حفظنا اسم العادة وأيامها ومدتها ووقت التذكير.")
        }
        .alert("تعذر الحفظ", isPresented: $showError) {
            Button("تمام", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var header: some View {
        HStack {
            Text(editing == nil ? "أضف عادة" : "تعديل العادة")
                .font(.system(size: 24, weight: .bold))

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(pink)
                    .frame(width: 44, height: 44)
                    .background(rowColor, in: Circle())
                    .overlay {
                        Circle().stroke(pink, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("رجوع")
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("اسم العادة")

            TextField("قراءة ١٠ صفحات", text: $habitName)
                .font(.system(size: 16))
                .multilineTextAlignment(.leading)
                .tint(pink)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(
                    surface,
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit {
                    nameFocused = false
                }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("الأيقونة")

            HStack(spacing: 8) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundStyle(pink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                selectedIcon == icon
                                    ? Color(
                                        red: 1,
                                        green: 0.96,
                                        blue: 0.83
                                    )
                                    : surface,
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon)
                    .accessibilityAddTraits(
                        selectedIcon == icon ? .isSelected : []
                    )
                }
            }
        }
    }

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("الأيام")

            HStack(spacing: 7) {
                ForEach(dayLabels.indices, id: \.self) { index in
                    let day = index
                    let selected = selectedDays.contains(day)

                    Button {
                        if selected {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    } label: {
                        Text(dayLabels[index])
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                selected ? surface : pink
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                selected ? pink : rowColor,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(pink, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(dayNames[index])
                    .accessibilityAddTraits(
                        selected ? .isSelected : []
                    )
                }
            }
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("وقت التذكير")

            HStack(spacing: 12) {
                Button {
                    nameFocused = false
                    showTimePicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                            .foregroundStyle(pink)

                        Text(
                            reminderTime,
                            format: .dateTime.hour().minute()
                        )
                        .font(.system(size: 15))

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("اختيار وقت التذكير")

                Toggle("تفعيل التذكير", isOn: $reminderEnabled)
                    .labelsHidden()
                    .tint(pink)
                    .scaleEffect(0.85)
                    .fixedSize()
            }
            .padding(.horizontal, 14)
            .background(
                rowColor,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
    }

    private var dailyGoalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("عدد المرات في اليوم")

            HStack {
                Button {
                    dailyGoal = min(dailyGoal + 1, 50)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(surface)
                        .frame(width: 40, height: 40)
                        .background(pink, in: Circle())
                }
                .disabled(dailyGoal == 50)
                .accessibilityLabel("زيادة عدد المرات")

                Spacer()

                Text("\(arabicNumber(dailyGoal)) مرة")
                    .font(.system(size: 17, weight: .bold))
                    .monospacedDigit()

                Spacer()

                Button {
                    dailyGoal = max(1, dailyGoal - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle().stroke(pink, lineWidth: 1)
                        }
                }
                .disabled(dailyGoal == 1)
                .opacity(dailyGoal == 1 ? 0.4 : 1)
                .accessibilityLabel("إنقاص عدد المرات")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(
                rowColor,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("المدة (أنت تحددها)")

            HStack {
                Button {
                    duration = min(duration + 1, 365)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(surface)
                        .frame(width: 40, height: 40)
                        .background(pink, in: Circle())
                }
                .accessibilityLabel("زيادة المدة يومًا")

                Spacer()

                Text("\(arabicNumber(duration)) يوم")
                    .font(.system(size: 17, weight: .bold))
                    .monospacedDigit()

                Spacer()

                Button {
                    duration = max(1, duration - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle().stroke(pink, lineWidth: 1)
                        }
                }
                .disabled(duration == 1)
                .opacity(duration == 1 ? 0.4 : 1)
                .accessibilityLabel("تقليل المدة يومًا")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(
                rowColor,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
    }

    private var timePickerSheet: some View {
        VStack(spacing: 12) {
            Text("وقت التذكير")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 24)

            DatePicker(
                "وقت التذكير",
                selection: $reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ar_SA"))
            .frame(maxWidth: .infinity)

            Button {
                showTimePicker = false
            } label: {
                Text("تم")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(surface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(pink, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
        .presentationBackground(rowColor)
        .preferredColorScheme(.dark)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func arabicNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func saveHabit() {
        guard canSave else { return }
        nameFocused = false

        let name = habitName.trimmingCharacters(in: .whitespacesAndNewlines)

        if var habit = editing {
            // التعديل يحافظ على التقدم ويغيّر الإعدادات فقط.
            habit.name = name
            habit.icon = selectedIcon
            habit.days = selectedDays
            habit.reminderEnabled = reminderEnabled
            habit.reminderTime = reminderTime
            habit.durationDays = duration
            habit.dailyGoal = dailyGoal
            store.update(habit)
            dismiss()
        } else {
            store.add(Habit(
                name: name,
                icon: selectedIcon,
                days: selectedDays,
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                durationDays: duration,
                dailyGoal: dailyGoal,
                constellationIndex: selectedStar
            ))
            showSavedMessage = true
        }
    }
}

#Preview {
    AddHabitView()
        .environment(HabitStore.preview)
}
