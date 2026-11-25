import LisdexCore
import SwiftUI

/// "On a Schedule" card: tap day pills to toggle them. When every day that's on shares its hours,
/// edit them inline (an end before the start runs overnight); otherwise show a summary and a link
/// to Settings → Schedule, where each day has its own hours.
struct ScheduleCard: View {
  let schedule: Schedule
  let update: (Schedule) -> Void
  let editHours: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Schedule", systemImage: "calendar")
        .font(.subheadline.weight(.semibold))
      WeekdayPills(schedule: schedule, update: update)
      if let hours = schedule.sharedHours {
        sharedHoursRow(hours)
      } else {
        VStack(alignment: .leading, spacing: 4) {
          Text(schedule.summary(calendar: .current))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
          Button("Edit Hours…", action: editHours)
            .buttonStyle(.link)
            .font(.caption)
        }
      }
    }
    .padding(10)
    .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
  }

  private func sharedHoursRow(_ hours: DayHours) -> some View {
    HStack(spacing: 6) {
      TimeField(label: "From", time: hours.start) {
        update(schedule.withSharedHours(DayHours(start: $0, end: hours.end)))
      }
      Text("–").foregroundStyle(.secondary)
      TimeField(label: "To", time: hours.end) {
        update(schedule.withSharedHours(DayHours(start: hours.start, end: $0)))
      }
      Spacer()
      if hours.isOvernight {
        Text("overnight").font(.caption).foregroundStyle(.secondary)
      }
    }
  }
}

/// One pill per weekday, Monday first; tapping one switches that day on or off. Shared by the
/// popover's schedule card and Settings → Automation.
struct WeekdayPills: View {
  @Environment(\.accent) private var accent
  let schedule: Schedule
  let update: (Schedule) -> Void

  var body: some View {
    HStack(spacing: 6) {
      ForEach(Weekday.displayOrder, id: \.self, content: pill)
    }
  }

  private func pill(_ day: Weekday) -> some View {
    let isOn = schedule.days.contains(day)
    return Button {
      update(schedule.toggling(day))
    } label: {
      Text(day.letter)
        .font(.caption.weight(.semibold))
        .frame(width: 26, height: 26)
        .foregroundStyle(isOn ? Color.black : .secondary)
        .background(isOn ? accent : Color.primary.opacity(0.08), in: .circle)
        .contentShape(.circle)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Calendar.current.weekdaySymbols[day.rawValue - 1])
    .accessibilityAddTraits(isOn ? .isSelected : [])
    .accessibilityValue(isOn ? "On" : "Off")
  }
}
