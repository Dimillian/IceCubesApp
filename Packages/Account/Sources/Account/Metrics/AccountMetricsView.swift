import Charts
import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftData
import SwiftUI

public struct AccountMetricsView: View {
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(MastodonClient.self) private var client
  @Environment(Theme.self) private var theme
  @Environment(RouterPath.self) private var routerPath
  @Environment(\.modelContext) private var modelContext
  @Environment(\.calendar) private var calendar

  private let metricsStore = AccountMetricsStore()

  @State private var range: MetricRange = .days7
  @State private var selectedMetric: MetricType = .follow
  @State private var chartStyle: MetricChartStyle = .bars
  @State private var dailyData: [DailyMetric] = []
  @State private var animatedDailyData: [DailyMetric] = []
  @State private var totals: [MetricType: Int] = [:]
  @State private var deltas: [MetricType: Double?] = [:]
  @State private var topStatusIds: [String] = []
  @State private var topStatuses: [Status] = []
  @State private var isLoadingTopStatuses = false
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
              delta: deltas[metric] ?? nil,
              isLoading: isLoading
            )
          }
        }

        if isLoadingTopStatuses || !topStatuses.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Top posts")
              .font(.headline)
              .foregroundStyle(theme.labelColor)
            if isLoadingTopStatuses && topStatuses.isEmpty {
              VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                  StatusEmbeddedView(
                    status: .placeholder(),
                    client: client,
                    routerPath: routerPath
                  )
                }
              }
              .redacted(reason: .placeholder)
              .frame(maxWidth: .infinity, alignment: .center)
            } else {
              ForEach(topStatuses) { status in
                StatusEmbeddedView(status: status, client: client, routerPath: routerPath)
              }
            }
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
    .task(id: topStatusIds) {
      await loadTopStatuses()
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
    let previousStartDate =
      calendar.date(byAdding: .day, value: -range.rawValue, to: startDate) ?? startDate
    let previousEndDate =
      calendar.date(byAdding: .day, value: -1, to: startDate) ?? startDate
    let server = client.server

    let descriptor = FetchDescriptor<MetricsNotificationGroup>(
      predicate: #Predicate {
        $0.accountId == accountId
          && $0.server == server
          && $0.dayStart >= previousStartDate
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
        .filter { metricTypes(for: selectedMetric).contains($0.type) }
        .reduce(0) { $0 + $1.notificationsCount }
      return DailyMetric(dayStart: dayStart, count: count)
    }

    let updatedTotals = Dictionary(
      uniqueKeysWithValues: MetricType.allCases.map { metric in
        let count = groups
          .filter { metricTypes(for: metric).contains($0.type) }
          .filter { $0.dayStart >= startDate && $0.dayStart <= endDate }
          .reduce(0) { $0 + $1.notificationsCount }
        return (metric, count)
      })

    let updatedDeltas: [MetricType: Double?] = Dictionary(
      uniqueKeysWithValues: MetricType.allCases.map { metric in
        let current = updatedTotals[metric] ?? 0
        let previous = groups
          .filter { metricTypes(for: metric).contains($0.type) }
          .filter { $0.dayStart >= previousStartDate && $0.dayStart <= previousEndDate }
          .reduce(0) { $0 + $1.notificationsCount }

        guard previous > 0 else {
          return (metric, nil)
        }

        let delta = (Double(current) - Double(previous)) / Double(previous)
        return (metric, delta)
      })

    let updatedTopStatusIds = topStatusIds(
      groups: groups,
      startDate: startDate,
      endDate: endDate
    )

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
      deltas = updatedDeltas
      topStatusIds = updatedTopStatusIds
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

  private func metricTypes(for metric: MetricType) -> [String] {
    switch metric {
    case .reblog:
      return ["reblog", "quote"]
    default:
      return [metric.rawValue]
    }
  }

  private func topStatusIds(
    groups: [MetricsNotificationGroup],
    startDate: Date,
    endDate: Date
  ) -> [String] {
    let counts = groups
      .filter { !$0.statusId.isEmpty }
      .filter { $0.dayStart >= startDate && $0.dayStart <= endDate }
      .reduce(into: [String: Int]()) { result, group in
        result[group.statusId, default: 0] += group.notificationsCount
      }

    return counts
      .sorted { $0.value > $1.value }
      .prefix(3)
      .map(\.key)
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
      try await backfillGroupsIfNeeded(
        accountId: accountId,
        server: client.server,
        force: forceBackfill
      )
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
  private func backfillGroupsIfNeeded(
    accountId: String,
    server: String,
    force: Bool
  ) async throws {
    let startDate = rangeStartDate()
    let groupedTypes = Set(MetricType.allCases.map(\.rawValue))
    var oldestDayStart = metricsStore.earliestStoredDayStart(
      accountId: accountId,
      server: server,
      modelContext: modelContext
    )

    if !force {
      guard oldestDayStart == nil || oldestDayStart! > startDate else { return }
    }

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
    let types = MetricType.allCases.map(\.rawValue) + ["quote"]
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

  @MainActor
  private func loadTopStatuses() async {
    let ids = topStatusIds
    guard !ids.isEmpty else {
      topStatuses = []
      return
    }

    isLoadingTopStatuses = true
    defer { isLoadingTopStatuses = false }

    let statuses = await withTaskGroup(of: (String, Status?).self) { group in
      for id in ids {
        group.addTask {
          let status: Status? = try? await client.get(endpoint: Statuses.status(id: id))
          return (id, status)
        }
      }

      var results: [String: Status] = [:]
      for await (id, status) in group {
        if let status {
          results[id] = status
        }
      }
      return ids.compactMap { results[$0] }
    }

    topStatuses = statuses
  }
}
