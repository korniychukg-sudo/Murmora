import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var store: MurmoraStore
    @Environment(\.presentationMode) var presentation

    private var days: [(date: Date, seconds: Double)] { store.recentDays(7) }
    private var peak: Double { max(60, days.map { $0.seconds }.max() ?? 60) }
    private var cats: [(cat: SoundCat, seconds: Double)] { store.secondsByCategory() }
    private var catTotal: Double { max(1, cats.reduce(0) { $0 + $1.seconds }) }

    var body: some View {
        ZStack {
            Murmora.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Insights").font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
                    Spacer()
                    Button { presentation.wrappedValue.dismiss() } label: {
                        ZStack { Circle().fill(Murmora.card).frame(width: 34, height: 34); MurmoraIcon(glyph: .close, size: 15, color: Murmora.ink) }
                    }
                }.padding(18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        streakCard
                        weekCard
                        if !cats.isEmpty { categoryCard }
                        totalsCard
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .frame(maxWidth: Murmora.contentMaxWidth)
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Murmora.gradient(.fire)).frame(width: 58, height: 58)
                Text("\(store.currentStreak)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(store.currentStreak == 1 ? "1 day in a row" : "\(store.currentStreak) days in a row")
                    .font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundColor(Murmora.ink)
                Text("Best run so far: \(store.bestStreak) \(store.bestStreak == 1 ? "day" : "days")")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
            }
            Spacer()
        }
        .murmoraCard(padding: 16, radius: 20)
    }

    // MARK: - Last 7 days

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Last 7 days", subtitle: "Minutes listened each day")
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 6) {
                        Text(d.seconds >= 60 ? "\(Int(d.seconds / 60))" : "")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(Murmora.subtle)
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(d.seconds > 0 ? Murmora.gradient(.tones)
                                                : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)],
                                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: max(6, 120 * (d.seconds / peak)))
                        Text(weekday(d.date))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Murmora.faint)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 165, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .murmoraCard(padding: 16, radius: 20)
    }

    private func weekday(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEEE"
        return f.string(from: d)
    }

    // MARK: - Categories

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "What you reach for", subtitle: "Share of listening by family")
            VStack(spacing: 10) {
                ForEach(cats, id: \.cat.id) { row in
                    HStack(spacing: 10) {
                        Circle().fill(Murmora.gradient(row.cat)).frame(width: 12, height: 12)
                        Text(row.cat.title)
                            .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                            .foregroundColor(Murmora.ink)
                            .frame(width: 130, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.07))
                                Capsule().fill(Murmora.gradient(row.cat))
                                    .frame(width: max(4, geo.size.width * (row.seconds / catTotal)))
                            }
                        }
                        .frame(height: 10)
                        Text("\(Int((row.seconds / catTotal) * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Murmora.subtle)
                            .frame(width: 38, alignment: .trailing)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .murmoraCard(padding: 16, radius: 20)
    }

    // MARK: - Totals

    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "All time", subtitle: "Since you installed Murmora")
            VStack(spacing: 9) {
                totalRow("Time listened", "\(store.stats.minutes) min")
                totalRow("Sessions", "\(store.stats.sessions)")
                totalRow("Longest session", "\(Int(store.stats.longestSeconds / 60)) min")
                totalRow("Sounds tried", "\(store.stats.usedSounds.count) of \(SoundCatalog.all.count)")
                totalRow("Scenes saved", "\(store.savedMixes.count)")
                totalRow("Sleep timers finished", "\(store.stats.sleepCompleted)")
                totalRow("Focus sessions finished", "\(store.stats.focusCompleted)")
                totalRow("Breathing sessions", "\(store.stats.breathSessions)")
                totalRow("Time breathing", "\(store.stats.breathMinutes) min")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .murmoraCard(padding: 16, radius: 20)
    }

    private func totalRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(Murmora.subtle)
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(Murmora.ink)
        }
    }
}
