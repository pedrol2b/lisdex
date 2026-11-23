import LisdexCore
import SwiftUI

/// Settings → Schedule: which days "On a Schedule" holds, each with its own hours
/// (spec per-day-schedule). A day that's off keeps its hours, greyed out.
struct ScheduleSettingsView: View {
  let model: AppModel

  private var schedule: Schedule { model.settings.schedule }

  var body: some View {
    Form {
      Section {
        ForEach(Weekday.displayOrder, id: \.self, content: row)
      } header: {
        Text("Hours for each day")
      } footer: {
        Text("A window that ends before it starts runs overnight.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .formStyle(.grouped)
  }

  private func row(_ day: Weekday) -> some View {
    let hours = schedule.hours(for: day)
    let isOn = schedule.days.contains(day)
    let name = Calendar.current.weekdaySymbols[day.rawValue - 1]
    return HStack(spacing: 6) {
      Toggle(
        name,
        isOn: Binding(get: { isOn }, set: { _ in model.setSchedule(schedule.toggling(day)) }))
      Spacer()
      if hours.isOvernight {
        Text("overnight").font(.caption).foregroundStyle(.secondary)
      }
      Group {
        TimeField(label: "\(name) from", time: hours.start) {
          model.setSchedule(schedule.with(hours: DayHours(start: $0, end: hours.end), for: day))
        }
        Text("–").foregroundStyle(.secondary)
        TimeField(label: "\(name) to", time: hours.end) {
          model.setSchedule(schedule.with(hours: DayHours(start: hours.start, end: $0), for: day))
        }
      }
      .disabled(!isOn)
    }
  }
}
