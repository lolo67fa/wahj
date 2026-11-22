import SwiftUI

// «سمائي»: السماء اللي تبنينها بإنجازاتك.
// - المجموعة المختارة كبيرة في وسط السماء، والضوء يمشي على مسارها الحقيقي (٥ نقاط لكل إنجاز).
// - التقدم والمراحل (٢٥ / ٥٠ / ٧٥ / ١٠٠) كلها من نفس سجل الإنجازات في HabitStore؛ ما فيه نقاط جديدة.
// - اللمس والسحب للاستعراض فقط، ولا يعطيان نقاطًا.
struct MySkyView: View {
    @Binding var selectedTab: Int
    // من الرئيسية تظهر صفحة مدفوعة بزر رجوع؛ من تبويب «نجمتي» يظهر شريط التبويبات.
    var showsBackButton = false

    @Environment(HabitStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    // مظهر التطبيق الفعلي (فاتح/داكن). السماء تبقى ليلية، والأزرار تتبع هذا المظهر.
    @Environment(\.colorScheme) private var appColorScheme

    // محفوظة لكل حساب (defaultAppStorage = بيانات الحساب).
    @AppStorage("selectedStarIndex") private var selectedStar = 0
    // آخر نقاط شافتها المستخدمة لكل مجموعة، عشان نحرّك الفرق الجديد فقط.
    @AppStorage("sky.lastSeenPoints.v1") private var lastSeenRaw = ""
    // المجموعات اللي انعرض احتفال اكتمالها، عشان ما يتكرر.
    @AppStorage("sky.celebrated.v1") private var celebratedRaw = ""

    @State private var displayedPoints: Double = 0
    @State private var isVisible = false
    @State private var pan: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    @State private var bubble: SkyBubble?
    @State private var flashStar: Int?
    @State private var tapCount = 0
    @State private var celebrating = false
    @State private var isChoosingStar = false

    private let maxPan: CGFloat = 70

    private var index: Int { min(max(selectedStar, 0), HabitProgress.constellationCount - 1) }
    private var points: Int { store.constellationPoints(index) }
    private var path: ConstellationPath { ConstellationPath(index: index) }
    private var name: String { StarProgress.names[index] }
    private var animationsPaused: Bool { reduceMotion || !isVisible || scenePhase != .active }

    private var offset: CGSize {
        CGSize(width: clamp(pan.width + drag.width), height: clamp(pan.height + drag.height))
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 10) {
                topBar
                header
                sky
                    .frame(maxHeight: .infinity)
                todayPanel
            }
            .padding(.horizontal, 20)
            .padding(.bottom, showsBackButton ? 16 : 0)

            if celebrating {
                CelebrationOverlay(
                    name: name,
                    nextName: StarProgress.names.indices.contains(index + 1) ? StarProgress.names[index + 1] : nil,
                    reduceMotion: reduceMotion,
                    onChooseNext: { celebrating = false; isChoosingStar = true },
                    onClose: { celebrating = false }
                )
                .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !showsBackButton {
                BottomTabBar(selected: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .environment(\.colorScheme, appColorScheme)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.layoutDirection, .rightToLeft)
        // «سمائي» سماء ليلية دائمًا، بدون ما تغيّر مظهر بقية التطبيق.
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.selection, trigger: tapCount)
        .sensoryFeedback(.success, trigger: celebrating) { _, new in new }
        .onAppear {
            isVisible = true
            reveal(animated: true)
        }
        .onDisappear { isVisible = false }
        // إنجاز أو إلغاء من صفحة ثانية، أو تغيير المجموعة.
        .onChange(of: points) { _, _ in reveal(animated: true) }
        .onChange(of: selectedStar) { _, _ in
            bubble = nil
            pan = .zero
            reveal(animated: false)
        }
        .sheet(isPresented: $isChoosingStar) {
            StarSelectionView()
        }
    }

    // MARK: - Top and header

    private var topBar: some View {
        HStack {
            if showsBackButton {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.surface, in: Circle())
                }
                .accessibilityLabel("رجوع")
                .environment(\.colorScheme, appColorScheme)
            }
            Text("سمائي")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.text)
            Spacer()
            if offset != .zero {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.5)) { pan = .zero }
                } label: {
                    Image(systemName: "scope")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.surface, in: Circle())
                }
                .accessibilityLabel("إعادة توسيط السماء")
                .environment(\.colorScheme, appColorScheme)
                .transition(.opacity)
            }
            Button { isChoosingStar = true } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.surface, in: Circle())
            }
            .accessibilityLabel("اختيار المجموعة")
            .environment(\.colorScheme, appColorScheme)
        }
        .padding(.top, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("\(arabicNumber(Int(displayedPoints.rounded()))) / ١٠٠ نقطة")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .contentTransition(.numericText(value: displayedPoints))
            }
            Text(path.nextGoal(from: points))
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Sky

    private var sky: some View {
        GeometryReader { geo in
            let size = geo.size
            let mainSize = CGSize(width: min(size.width * 0.82, 320), height: min(size.height * 0.55, 260))

            ZStack {
                // نجوم بعيدة تتحرك بهدوء (تتوقف لما الصفحة مخفية أو مع Reduce Motion)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: animationsPaused)) { context in
                    DistantStars(time: context.date.timeIntervalSinceReferenceDate,
                                 moving: !animationsPaused,
                                 shootingStars: displayedPoints >= 75 && !reduceMotion)
                        .offset(x: offset.width * 0.3, y: offset.height * 0.3)
                }
                .accessibilityHidden(true)

                // المجموعات المكتملة والمقفلة في خلفية السماء (أصغر)
                ForEach(backgroundSlots(in: size), id: \.index) { slot in
                    backgroundConstellation(slot)
                        .offset(x: offset.width * 0.6, y: offset.height * 0.6)
                }

                // المجموعة المختارة: الأبرز في الوسط
                mainConstellation(size: mainSize, skySize: size)
                    .position(x: size.width / 2, y: size.height / 2)
                    .offset(offset)

                if let bubble {
                    bubbleView(bubble)
                        .position(x: min(max(bubble.point.x, 110), size.width - 110),
                                  y: max(bubble.point.y - 44, 30))
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            // إحداثيات السماء ثابتة (لا تنعكس مع العربية)؛ النصوص داخلها تبقى RTL.
            .environment(\.layoutDirection, .leftToRight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .updating($drag) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        pan = CGSize(width: clamp(pan.width + value.translation.width),
                                     height: clamp(pan.height + value.translation.height))
                    }
            )
        }
        .clipped()
    }

    private func mainConstellation(size: CGSize, skySize: CGSize) -> some View {
        let progress = displayedPoints / Double(HabitProgress.pointsPerConstellation)
        // Where the main constellation's frame sits inside the sky (for the info bubble).
        let origin = CGPoint(x: (skySize.width - size.width) / 2 + offset.width,
                             y: (skySize.height - size.height) / 2 + offset.height)

        return ZStack {
            // ٢٥ نقطة: توهج إضافي دائم خلف المجموعة
            if displayedPoints >= 25 {
                Circle()
                    .fill(RadialGradient(colors: [AppTheme.gold.opacity(0.22), .clear],
                                         center: .center, startRadius: 0, endRadius: size.width * 0.6))
                    .frame(width: size.width * 1.2, height: size.width * 1.2)
                    .transition(.opacity)
            }

            // ٥٠ نقطة: مدار بتفاصيل يدور ببطء
            if displayedPoints >= 50 {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: animationsPaused)) { context in
                    let angle = animationsPaused ? 0 : context.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: 90) / 90 * 360
                    OrbitRings(rotation: angle)
                        .frame(width: size.width * 0.95, height: size.width * 0.95)
                        .opacity(0.8)
                }
                .transition(.opacity)
                .accessibilityHidden(true)
            }

            ConstellationDrawing(index: index, progress: progress, locked: false,
                                 lightsAlongPath: true, pulse: true)
                .frame(width: size.width, height: size.height)
                // The tap targets sit on the drawing's own frame, so they stay on the stars
                // even when the halo and orbit (bigger than the drawing) are shown.
                .overlay { starTargets(size: size, origin: origin) }
        }
        .frame(width: size.width, height: size.height)
        .environment(\.layoutDirection, .leftToRight)   // لا نعكس هندسة المجموعة
        .accessibilityElement(children: .contain)
        .accessibilityLabel("المجموعة \(name)، \(arabicNumber(points)) من ١٠٠ نقطة")
    }

    // لمس نجمة: معلومة مختصرة + وهج مؤقت + Haptic خفيف (بدون نقاط)
    private func starTargets(size: CGSize, origin: CGPoint) -> some View {
        ZStack {
            ForEach(Array(path.stars.enumerated()), id: \.offset) { star, unit in
                let point = CGPoint(x: unit.x * size.width, y: unit.y * size.height)
                Button {
                    tapCount += 1
                    withAnimation(.easeOut(duration: 0.2)) {
                        flashStar = star
                        bubble = SkyBubble(text: path.starInfo(star, points: points),
                                           point: CGPoint(x: origin.x + point.x, y: origin.y + point.y))
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(1.2))
                        withAnimation(.easeOut(duration: 0.6)) { if flashStar == star { flashStar = nil } }
                    }
                    hideBubbleLater()
                } label: {
                    Circle()
                        .fill(AppTheme.gold.opacity(flashStar == star ? 0.45 : 0.001))
                        .frame(width: flashStar == star ? 40 : 44, height: flashStar == star ? 40 : 44)
                        .blur(radius: flashStar == star ? 8 : 0)
                }
                .buttonStyle(.plain)
                .position(point)
                .accessibilityLabel(path.starInfo(star, points: points))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func backgroundConstellation(_ slot: SkySlot) -> some View {
        let state = slotState(slot.index)
        return ConstellationDrawing(index: slot.index, progress: state == .complete ? 1 : 0, locked: false)
            .frame(width: 92, height: 70)
            .opacity(state == .complete ? 0.75 : 0.22)
            .scaleEffect(0.95)
            .position(slot.point)
            .onTapGesture {
                tapCount += 1
                withAnimation(.easeOut(duration: 0.2)) {
                    bubble = SkyBubble(text: backgroundInfo(slot.index), point: slot.point)
                }
                hideBubbleLater()
            }
            .accessibilityElement()
            .accessibilityLabel(backgroundInfo(slot.index))
            .accessibilityAddTraits(.isButton)
    }

    private enum SlotState { case complete, inProgress, locked }

    private func slotState(_ i: Int) -> SlotState {
        if store.constellations.isComplete(i) { return .complete }
        return store.isConstellationUnlocked(i) ? .inProgress : .locked
    }

    private func backgroundInfo(_ i: Int) -> String {
        let starName = StarProgress.names[i]
        switch slotState(i) {
        case .complete:
            return "«\(starName)» مكتملة · ١٠٠ نقطة"
        case .inProgress:
            return "«\(starName)» · \(arabicNumber(store.constellationPoints(i))) / ١٠٠ نقطة — اخترها من زر المجموعات"
        case .locked:
            let previous = i > 0 ? StarProgress.names[i - 1] : starName
            return "«\(starName)» مقفلة · تنفتح لما تكمل «\(previous)»"
        }
    }

    // Fixed spots around the edge of the sky for the other five constellations.
    private func backgroundSlots(in size: CGSize) -> [SkySlot] {
        let spots: [CGPoint] = [
            CGPoint(x: 0.16, y: 0.10), CGPoint(x: 0.84, y: 0.09),
            CGPoint(x: 0.12, y: 0.90), CGPoint(x: 0.88, y: 0.91),
            CGPoint(x: 0.50, y: 0.95)
        ]
        let others = (0..<HabitProgress.constellationCount).filter { $0 != index }
        return zip(others, spots).map { i, spot in
            SkySlot(index: i, point: CGPoint(x: spot.x * size.width, y: spot.y * size.height))
        }
    }

    private func bubbleView(_ bubble: SkyBubble) -> some View {
        Text(bubble.text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppTheme.text)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: 220)
            .background(AppTheme.surface.opacity(0.95), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border, lineWidth: 1))
            .environment(\.layoutDirection, .rightToLeft)
            .allowsHitTesting(false)
    }

    // MARK: - Today

    private var todayPanel: some View {
        let due = store.habits.filter { !$0.isDemoData && store.isDue($0, on: store.today) }
        let done = due.filter { store.isCompleted($0, on: store.today) }.count
        let complete = store.constellations.isComplete(index)

        return VStack(spacing: 10) {
            HStack {
                Text(due.isEmpty
                     ? "ما فيه عادات مستحقة اليوم"
                     : "أنجزت \(arabicNumber(done)) من \(arabicNumber(due.count)) عادات اليوم")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Label("\(arabicNumber(store.appStreak))", systemImage: "flame.fill")
                    .font(.footnote.bold())
                    .foregroundStyle(AppTheme.gold)
                    .accessibilityLabel("الستريك \(arabicNumber(store.appStreak)) أيام")
            }

            if complete && store.isConstellationUnlocked(index + 1) {
                Button { isChoosingStar = true } label: {
                    Text("اختار مجموعتك التالية").bold()
                        .foregroundStyle(AppTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppTheme.accent, in: Capsule())
                }
            }

            Button {
                // عادات اليوم الموجودة في «عاداتي»
                selectedTab = 1
                if showsBackButton { dismiss() }
            } label: {
                Text("كمّل عاداتك").bold()
                    .foregroundStyle(complete ? AppTheme.text : AppTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(complete ? AppTheme.elevated : AppTheme.accent, in: Capsule())
            }
        }
        .padding(14)
        .background(AppTheme.surface.opacity(appColorScheme == .light ? 0.95 : 0.85), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.border, lineWidth: 1))
        .environment(\.colorScheme, appColorScheme)
    }

    // MARK: - Progress reveal

    // Shows the progress. Only the part added since the last visit animates,
    // and the 100-point celebration plays once per constellation.
    private func reveal(animated: Bool) {
        var seen = lastSeen
        let current = points
        let start = Double(seen[index] ?? current)

        if animated && !reduceMotion && Int(start) < current {
            displayedPoints = start
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.easeInOut(duration: 1.2)) { displayedPoints = Double(current) }
            }
        } else {
            displayedPoints = Double(current)
        }

        seen[index] = current
        lastSeen = seen

        var done = celebrated
        if current >= HabitProgress.pointsPerConstellation && !done.contains(index) {
            done.insert(index)
            celebrated = done
            Task {
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 1700))
                withAnimation(.easeOut(duration: 0.3)) { celebrating = true }
            }
        }
    }

    private var lastSeen: [Int: Int] {
        get {
            Dictionary(uniqueKeysWithValues: lastSeenRaw.split(separator: ",").compactMap { pair in
                let parts = pair.split(separator: ":").compactMap { Int($0) }
                return parts.count == 2 ? (parts[0], parts[1]) : nil
            })
        }
        nonmutating set {
            lastSeenRaw = newValue.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: ",")
        }
    }

    private var celebrated: Set<Int> {
        get { Set(celebratedRaw.split(separator: ",").compactMap { Int($0) }) }
        nonmutating set { celebratedRaw = newValue.sorted().map(String.init).joined(separator: ",") }
    }

    private func clamp(_ value: CGFloat) -> CGFloat { min(max(value, -maxPan), maxPan) }

    // The info bubble fades by itself, so a later tap never fights with it.
    private func hideBubbleLater() {
        let shown = bubble
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.4)) { if bubble == shown { bubble = nil } }
        }
    }
}

// MARK: - Path maths

// The same lighting rule as ConstellationDrawing(lightsAlongPath:), used for the
// "next star" goal and the star info. Built from the drawing's real geometry.
struct ConstellationPath {
    let stars: [CGPoint]
    let edges: [(Int, Int)]

    init(index: Int) {
        let drawing = ConstellationDrawing(index: index, progress: 0, locked: false)
        stars = drawing.points
        edges = drawing.edges
    }

    func litStars(at points: Int) -> Set<Int> {
        let progress = Double(min(max(points, 0), 100)) / 100
        guard progress > 0 else { return [] }
        if progress >= 1 { return Set(stars.indices) }
        let along = progress * Double(edges.count)
        var lit = Set<Int>()
        for (i, edge) in edges.enumerated() {
            let fill = min(max(along - Double(i), 0), 1)
            if fill > 0 { lit.insert(edge.0) }
            if fill >= 1 { lit.insert(edge.1) }
        }
        return lit
    }

    // Points needed (in steps of 5) before the given star — or the next new star — lights up.
    func pointsUntilLit(star: Int? = nil, from points: Int) -> Int? {
        let before = litStars(at: points)
        var p = points
        while p < 100 {
            p += HabitProgress.pointsPerCompletion
            let now = litStars(at: p)
            if let star { if now.contains(star) { return p - points } }
            else if now.count > before.count { return p - points }
        }
        return nil
    }

    func nextGoal(from points: Int) -> String {
        if points >= 100 { return "اكتملت المجموعة! كل نجومها مضيئة" }
        guard let needed = pointsUntilLit(from: points) else { return "" }
        let completions = Int((Double(needed) / Double(HabitProgress.pointsPerCompletion)).rounded(.up))
        if points == 0 { return "\(completionsText(completions)) يضيء أول نجمة" }
        return "باقي \(completionsText(completions)) لإضاءة النجمة التالية"
    }

    func starInfo(_ star: Int, points: Int) -> String {
        let title = "النجمة \(arabicNumber(star + 1)) من \(arabicNumber(stars.count))"
        if litStars(at: points).contains(star) { return "\(title) · مضيئة ✨" }
        guard let needed = pointsUntilLit(star: star, from: points) else { return title }
        let completions = needed / HabitProgress.pointsPerCompletion
        return "\(title) · تضيء بعد \(completionsText(completions))"
    }

    // Arabic number agreement: إنجاز واحد، إنجازان، ٣ إنجازات، ١١ إنجازًا
    private func completionsText(_ n: Int) -> String {
        switch n {
        case 1: return "إنجاز واحد"
        case 2: return "إنجازان"
        case 3...10: return "\(arabicNumber(n)) إنجازات"
        default: return "\(arabicNumber(n)) إنجازًا"
        }
    }
}

private struct SkySlot { let index: Int; let point: CGPoint }

private struct SkyBubble: Equatable {
    let text: String
    let point: CGPoint
}

// MARK: - Distant stars

// Far stars drifting slowly and twinkling; from 75 points an occasional soft
// shooting star. Drawn with Canvas; frozen when `moving` is false.
private struct DistantStars: View {
    let time: TimeInterval
    let moving: Bool
    let shootingStars: Bool

    var body: some View {
        Canvas { context, size in
            let t = moving ? time : 0
            for i in 0..<70 {
                let seedX = Double((i * 73 + 11) % 347) / 347
                let seedY = Double((i * 47 + 7) % 229) / 229
                let speed = 0.002 + Double(i % 5) * 0.0012
                let x = (seedX + t * speed).truncatingRemainder(dividingBy: 1) * size.width
                let y = seedY * size.height
                let radius = i % 6 == 0 ? 1.4 : 0.8
                let twinkle = 0.35 + 0.35 * (sin(t * 0.8 + Double(i)) + 1) / 2
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                             with: .color(.white.opacity(twinkle)))
            }

            guard shootingStars else { return }
            // One soft streak every ~9 seconds, lasting about one second.
            let cycle = t.truncatingRemainder(dividingBy: 9)
            if cycle < 1.1 {
                let p = cycle / 1.1
                let start = CGPoint(x: size.width * (0.85 - 0.5 * p), y: size.height * (0.08 + 0.18 * p))
                let tail = CGPoint(x: start.x + 46, y: start.y - 16)
                var streak = Path()
                streak.move(to: start)
                streak.addLine(to: tail)
                context.stroke(streak, with: .linearGradient(
                    Gradient(colors: [AppTheme.gold.opacity(0.9 * (1 - p)), .clear]),
                    startPoint: start, endPoint: tail), lineWidth: 1.6)
            }
        }
    }
}

// MARK: - Celebration (once per constellation)

private struct CelebrationOverlay: View {
    let name: String
    let nextName: String?
    let reduceMotion: Bool
    var onChooseNext: () -> Void
    var onClose: () -> Void

    @State private var start = Date.now

    var body: some View {
        ZStack {
            AppTheme.background.opacity(0.7).ignoresSafeArea()
                .onTapGesture(perform: onClose)

            if !reduceMotion {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(start)
                    Canvas { ctx, size in
                        guard elapsed < 2.4 else { return }
                        let center = CGPoint(x: size.width / 2, y: size.height * 0.4)
                        for i in 0..<36 {
                            let angle = Double(i) / 36 * 2 * .pi
                            let distance = elapsed * (120 + Double(i % 4) * 30)
                            let point = CGPoint(x: center.x + cos(angle) * distance,
                                                y: center.y + sin(angle) * distance)
                            let alpha = max(0, 1 - elapsed / 2.4)
                            ctx.fill(Path(ellipseIn: CGRect(x: point.x, y: point.y, width: 4, height: 4)),
                                     with: .color(AppTheme.gold.opacity(alpha)))
                        }
                    }
                }
                .allowsHitTesting(false)
                .ignoresSafeArea()
            }

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.gold)
                Text("اكتملت «\(name)»!")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.text)
                Text(nextName.map { "كل نجومها مضيئة، وانفتحت «\($0)»" } ?? "كل نجومها مضيئة")
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                if nextName != nil {
                    Button(action: onChooseNext) {
                        Text("اختار مجموعتك التالية").bold()
                            .foregroundStyle(AppTheme.onAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.accent, in: Capsule())
                    }
                }
                Button("تم", action: onClose)
                    .foregroundStyle(AppTheme.text)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .padding(22)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 26))
            .padding(.horizontal, 32)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .accessibilityAddTraits(.isModal)
    }
}

#Preview {
    MySkyView(selectedTab: .constant(2))
        .environment(HabitStore.preview)
}
