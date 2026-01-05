import Charts
import DesignSystem
import Env
import Models
import NetworkClient
import SwiftData
import SwiftUI

public struct AccountMetricsView: View {
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(MastodonClient.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(\.modelContext) private var modelContext
  @Environment(\.calendar) private var calendar

  private let metricsStore = AccountMetricsStore()

  @State private var range: MetricRange = .days7
  @State private var selectedMetric: MetricType = .follow
  @State private var chartStyle: MetricChartStyle = .bars
  @State private var dailyData: [DailyMetric] = []
  @State private var animatedDailyData: [DailyMetric] = []
  @State private var totals: [MetricType: Int] = [:]
  @State private var isLoading = false

  private var taskId: String {
    let accountId = currentAccount.account?.id ?? "none"
    return "\(accountId)-\(client.server)-\(range.rawValue)"
  }

  public init() {}

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Picker("Range", selection: $range) {
          ForEach(MetricRange.allCases) { range in
            Text(range.title).tag(range)
          }
        }
        .pickerStyle(.segmented)

        MetricsChartCard(
          dailyData: dailyData,
          animatedDailyData: animatedDailyData,
          isLoading: isLoading,
          selectedMetric: selectedMetric,
          range: range,
          chartStyle: $chartStyle,
          maxValue: dailyData.map(\.count).max() ?? 0,
          onSelectMetric: { metric in
            selectedMetric = metric
            rebuildMetrics()
          }
        )

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
          ForEach(MetricType.allCases) { metric in
            MetricSummaryCard(
              title: metric.title,
              value: totals[metric] ?? 0,
              isLoading: isLoading
            )
          }
        }

        if dailyData.isEmpty {
          ContentUnavailableView(
            isLoading ? "Loading metrics…" : "No metrics yet",
            systemImage: "chart.bar"
          )
          .frame(maxWidth: .infinity)
          .padding(.top, 12)
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 16)
    }
    .navigationTitle("Metrics")
    .background(theme.primaryBackgroundColor)
    .task(id: taskId) {
      await refreshMetrics(forceBackfill: true)
    }
    .refreshable {
      await refreshMetrics(forceBackfill: false)
    }
  }

  @MainActor
  private func rebuildMetrics() {
    guard let accountId = currentAccount.account?.id else {
      dailyData = []
      totals = [:]
      return
    }

    let startDate = rangeStartDate()
    let endDate = calendar.startOfDay(for: Date())
    let server = client.server

    let descriptor = FetchDescriptor<MetricsNotificationGroup>(
      predicate: #Predicate {
        $0.accountId == accountId
          && $0.server == server
          && $0.dayStart >= startDate
          && $0.dayStart <= endDate
      },
      sortBy: [SortDescriptor(\.dayStart, order: .forward)]
    )

    let groups = (try? modelContext.fetch(descriptor)) ?? []
    let groupedByDay = Dictionary(grouping: groups) { $0.dayStart }
    let dayStarts = dayStartsInRange(startDate: startDate, endDate: endDate)

    let updatedDailyData = dayStarts.map { dayStart in
      let dayGroups = groupedByDay[dayStart] ?? []
      let count =
        dayGroups
        .filter { $0.type == selectedMetric.rawValue }
        .reduce(0) { $0 + $1.notificationsCount }
      return DailyMetric(dayStart: dayStart, count: count)
    }

    let updatedTotals = Dictionary(
      uniqueKeysWithValues: MetricType.allCases.map { metric in
        let count =
          groups
          .filter { $0.type == metric.rawValue }
          .reduce(0) { $0 + $1.notificationsCount }
        return (metric, count)
      })

    if updatedDailyData.isEmpty {
      dailyData = []
      animatedDailyData = []
    } else {
      dailyData = updatedDailyData
      animatedDailyData = updatedDailyData.map { DailyMetric(dayStart: $0.dayStart, count: 0) }
      withAnimation(.easeOut(duration: 0.35)) {
        animatedDailyData = updatedDailyData
      }
    }

    withAnimation(.snappy) {
      totals = updatedTotals
    }
  }

  private func rangeStartDate() -> Date {
    let endDate = calendar.startOfDay(for: Date())
    return calendar.date(byAdding: .day, value: -(range.rawValue - 1), to: endDate) ?? endDate
  }

  private func dayStartsInRange(startDate: Date, endDate: Date) -> [Date] {
    let dayCount = range.rawValue
    return (0..<dayCount).compactMap { offset in
      calendar.date(byAdding: .day, value: offset, to: startDate)
    }
  }

}

extension AccountMetricsView {
  @MainActor
  private func refreshMetrics(forceBackfill: Bool) async {
    guard !isLoading, let accountId = currentAccount.account?.id else { return }
    isLoading = true
    defer { isLoading = false }

    do {
      try await syncLatestGroups(accountId: accountId, server: client.server)
      if forceBackfill {
        try await backfillGroupsIfNeeded(accountId: accountId, server: client.server)
      }
      metricsStore.pruneOldGroups(
        accountId: accountId,
        server: client.server,
        keepingDays: 90,
        modelContext: modelContext
      )
      rebuildMetrics()
    } catch {
      rebuildMetrics()
    }
  }

  @MainActor
  private func syncLatestGroups(accountId: String, server: String) async throws {
    let sinceId = metricsStore.latestStoredNotificationId(
      accountId: accountId,
      server: server,
      modelContext: modelContext
    )
    let groups = try await fetchGroups(
      sinceId: sinceId.map(String.init),
      maxId: nil
    )
    metricsStore.upsert(
      groups: groups,
      accountId: accountId,
      server: server,
      modelContext: modelContext
    )
  }

  @MainActor
  private func backfillGroupsIfNeeded(accountId: String, server: String) async throws {
    let startDate = rangeStartDate()
    let groupedTypes = Set(MetricType.allCases.map(\.rawValue))
    var oldestDayStart = metricsStore.earliestStoredDayStart(
      accountId: accountId,
      server: server,
      modelContext: modelContext
    )

    guard oldestDayStart == nil || oldestDayStart! > startDate else { return }

    var remainingPages = 12
    var maxId = metricsStore.oldestStoredNotificationId(
      accountId: accountId,
      server: server,
      modelContext: modelContext
    ).map(String.init)

    while remainingPages > 0 {
      remainingPages -= 1
      let groups = try await fetchGroups(sinceId: nil, maxId: maxId)
      if groups.isEmpty {
        break
      }

      metricsStore.upsert(
        groups: groups,
        accountId: accountId,
        server: server,
        modelContext: modelContext
      )
      maxId = groups.last?.mostRecentNotificationId.description
      oldestDayStart = metricsStore.earliestStoredDayStart(
        accountId: accountId,
        server: server,
        modelContext: modelContext
      )

      if let oldestDayStart, oldestDayStart <= startDate {
        break
      }

      let hasRelevantType = groups.contains { groupedTypes.contains($0.type) }
      if !hasRelevantType {
        break
      }
    }
  }

  @MainActor
  private func fetchGroups(
    sinceId: String?,
    maxId: String?
  ) async throws -> [NotificationGroup] {
    let types = MetricType.allCases.map(\.rawValue)
    let groupedTypes = ["favourite", "follow", "reblog"]

    let results: GroupedNotificationsResults = try await client.get(
      endpoint: Notifications.notificationsV2(
        sinceId: sinceId,
        maxId: maxId,
        types: types,
        excludeTypes: nil,
        accountId: nil,
        groupedTypes: groupedTypes,
        expandAccounts: "full"
      ),
      forceVersion: .v2
    )

    return results.notificationGroups
  }
}
