import LisdexCore
import SwiftUI

/// Settings → Automation: what Lisdex does on its own — the schedule, apps that keep the Mac
/// awake, and keeping you active in chat apps (ADR 0026).
struct AutomationSettingsView: View {
  let model: AppModel

  var body: some View {
    Form {
      ScheduleSection(model: model)
      AppTriggerSection(model: model)
      JigglerSection(model: model)
    }
    .formStyle(.grouped)
  }
}

/// Day pills plus one shared From–To; "Different hours per day" lists each day that's on with its
/// own hours (ADR 0021). It shows on by itself when the days already differ; switching it off
/// gives every day the first selected day's hours.
private struct ScheduleSection: View {
  let model: AppModel
  /// The user's choice this session; the schedule decides when they haven't made one.
  @State private var wantsPerDay = false

  private var schedule: Schedule { model.settings.schedule }
  private var showsPerDay: Bool { wantsPerDay || schedule.sharedHours == nil }

  var body: some View {
    Section {
      LabeledContent("Days") {
        WeekdayPills(schedule: schedule, update: model.setSchedule)
      }
      if !showsPerDay, let hours = schedule.sharedHours {
        hoursRow(title: "Hours", hours: hours) { model.setSchedule(schedule.withSharedHours($0)) }
      }
      Toggle(
        "Different hours per day",
        isOn: Binding(
          get: { showsPerDay },
          set: { on in
            wantsPerDay = on
            if !on { model.setSchedule(schedule.unifyingHours()) }
          }))
      if showsPerDay {
        ForEach(Weekday.displayOrder.filter(schedule.days.contains), id: \.self) { day in
          hoursRow(title: Self.name(of: day), hours: schedule.hours(for: day)) {
            model.setSchedule(schedule.with(hours: $0, for: day))
          }
        }
      }
    } header: {
      Text("Schedule")
    } footer: {
      SectionFooter(
        "Used when the mode is On a Schedule. An end time before the start time runs overnight.")
    }
  }

  private func hoursRow(
    title: String, hours: DayHours, set: @escaping (DayHours) -> Void
  ) -> some View {
    LabeledContent {
      HStack(spacing: 6) {
        TimeField(label: "\(title) from", time: hours.start) {
          set(DayHours(start: $0, end: hours.end))
        }
        Text("to").foregroundStyle(.secondary)
        TimeField(label: "\(title) to", time: hours.end) {
          set(DayHours(start: hours.start, end: $0))
        }
      }
    } label: {
      Text(title)
      if hours.isOvernight { Text("Runs overnight") }
    }
  }

  private static func name(of day: Weekday) -> String {
    Calendar.current.weekdaySymbols[day.rawValue - 1]
  }
}
