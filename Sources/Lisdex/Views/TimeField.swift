import LisdexCore
import SwiftUI

/// Hour-and-minute stepper field for a `TimeOfDay` (schedule card and Settings → Schedule).
struct TimeField: View {
  let label: String
  let time: TimeOfDay
  let set: (TimeOfDay) -> Void

  var body: some View {
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
    DatePicker(label, selection: binding, displayedComponents: .hourAndMinute)
      .datePickerStyle(.stepperField)
      .labelsHidden()
      .accessibilityLabel(label)
  }
}
