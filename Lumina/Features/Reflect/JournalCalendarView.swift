import SwiftData
import SwiftUI

/// Month-grid calendar for the journal. Days with an entry get a small
/// dot indicator; tapping a day opens that day's entry detail (or a
/// fresh editor if none exists).
struct JournalCalendarView: View {
    /// Identifiable wrapper so `.navigationDestination(item:)` can present
    /// a tapped day without forcing `Date: Identifiable` globally.
    private struct SelectedDay: Identifiable, Hashable, Sendable {
        let date: Date
        var id: TimeInterval { date.timeIntervalSinceReferenceDate }
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var selectedDay: SelectedDay?
    @State private var monthCursor: Date = .now

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: LuminaSpacing.lg) {
            monthHeader
            weekdayLabels
            dayGrid
            Spacer()
        }
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedDay) { day in
            if let existing = entry(on: day.date) {
                JournalEntryDetailView(entry: existing)
            } else {
                JournalEntryView(entry: makeEntry(for: day.date))
            }
        }
    }

    // MARK: - Sub-views

    private var monthHeader: some View {
        HStack {
            Button {
                monthCursor = calendar.date(byAdding: .month, value: -1, to: monthCursor) ?? monthCursor
            } label: {
                Image(systemName: "chevron.left").foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(monthLabel)
                .font(LuminaTypography.heading)
            Spacer()
            Button {
                monthCursor = calendar.date(byAdding: .month, value: 1, to: monthCursor) ?? monthCursor
            } label: {
                Image(systemName: "chevron.right").foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
            .accessibilityLabel("Next month")
        }
    }

    private var weekdayLabels: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(LuminaTypography.mono)
                    .tracking(1.0)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        let days = monthDays
        let columns = Array(repeating: GridItem(.flexible(), spacing: LuminaSpacing.xs), count: 7)
        return LazyVGrid(columns: columns, spacing: LuminaSpacing.xs) {
            ForEach(0..<days.count, id: \.self) { index in
                cell(days[index])
            }
        }
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthCursor)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? []
        let firstWeekday = calendar.firstWeekday - 1
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday])
    }

    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: monthCursor) else { return [] }
        let start = interval.start
        let firstWeekdayOfMonth = calendar.component(.weekday, from: start)
        let leading = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: monthCursor)?.count ?? 0
        var slots: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            slots.append(calendar.date(byAdding: .day, value: offset, to: start))
        }
        while slots.count % 7 != 0 { slots.append(nil) }
        return slots
    }

    // MARK: - Methods

    @ViewBuilder
    private func cell(_ day: Date?) -> some View {
        if let day {
            if isFuture(day) {
                // You can't reflect on a day that hasn't happened — show the
                // number dimmed and non-interactive so no future-dated entry
                // is ever created.
                dayContent(day)
                    .opacity(0.35)
                    .accessibilityHidden(true)
            } else {
                Button {
                    selectedDay = SelectedDay(date: day)
                } label: {
                    dayContent(day)
                }
                .buttonStyle(.plain)
            }
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: 44)
        }
    }

    private func dayContent(_ day: Date) -> some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: day))")
                .font(LuminaTypography.body)
                .foregroundStyle(isToday(day) ? LuminaColors.celestialBlue : LuminaColors.inkBlack)
            Circle()
                .fill(hasEntry(on: day) ? LuminaColors.mutedGold : Color.clear)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }

    private func entry(on day: Date) -> JournalEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: day) }
    }

    private func hasEntry(on day: Date) -> Bool {
        entry(on: day) != nil
    }

    private func isToday(_ day: Date) -> Bool {
        calendar.isDateInToday(day)
    }

    private func isFuture(_ day: Date) -> Bool {
        calendar.compare(day, to: .now, toGranularity: .day) == .orderedDescending
    }

    private func makeEntry(for day: Date) -> JournalEntry {
        let prompt = JournalPromptGenerator.shared.prompt(for: day)
        let key = JournalPromptGenerator.shared.transitKey(for: day)
        let entry = JournalEntry(date: day, prompt: prompt, transitKey: key)
        modelContext.insert(entry)
        modelContext.saveOrLog(category: "Reflect")
        return entry
    }
}
