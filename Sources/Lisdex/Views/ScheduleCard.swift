import LisdexCore
import SwiftUI

/// "On a Schedule" card: tap day pills to toggle them, edit the window's start and end inline.
/// An end before the start runs overnight.
struct ScheduleCard: View {
  @Environment(\.accent) private var accent
  let schedule: Schedule
  let update: (Schedule) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Schedule", systemImage: "calendar")
        .font(.subheadline.weight(.semibold))
      HStack(spacing: 6) {
        ForEach(Weekday.displayOrder, id: \.self) { day in
          dayPill(day)
        }
      }
      HStack(spacing: 6) {
        timePicker("From", schedule.start) { update(schedule.with(start: $0)) }
        Text("–").foregroundStyle(.secondary)
        timePicker("To", schedule.end) { update(schedule.with(end: $0)) }
        Spacer()
        if schedule.end < schedule.start {
          Text("overnight").font(.caption).foregroundStyle(.secondary)
        }
      }
    }
    .padding(10)
    .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
  }

  private func dayPill(_ day: Weekday) -> some View {
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

  private func timePicker(_ label: String, _ time: TimeOfDay, set: @escaping (TimeOfDay) -> Void)
    -> some View
  {
    let calendar = Calendar.current
    let binding = Binding<Date>(
      get: {
        calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: .now) ?? .now
      },
      set: { date in
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        set(TimeOfDay(hour: parts.hour ?? 0, minute: parts.minute ?? 0))
      }
    )
    return DatePicker(label, selection: binding, displayedComponents: .hourAndMinute)
      .datePickerStyle(.stepperField)
      .labelsHidden()
      .accessibilityLabel(label)
  }
}
