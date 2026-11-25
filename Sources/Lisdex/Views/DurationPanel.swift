import LisdexCore
import SwiftUI

/// "For a Duration" controls: preset chips and a custom length (the timer's progress is on the
/// status card).
/// Picking a chip (re)starts the timer (spec, state 3).
struct DurationPanel: View {
  static let customRange = 5...(24 * 60)
  static let customStep = 5

  let model: AppModel
  @State private var showsCustom = false
  @State private var customMinutes = 45

  private var selected: TimeInterval { model.settings.duration }
  private var isCustomSelected: Bool { !DurationPreset.all.map(\.seconds).contains(selected) }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 4) {
        ForEach(DurationPreset.all, id: \.seconds) { preset in
          Chip(
            title: preset.title, spokenTitle: DurationText.spoken(preset.seconds),
            isSelected: preset.seconds == selected
          ) {
            showsCustom = false
            model.startDuration(preset.seconds)
          }
        }
        Chip(
          title: isCustomSelected ? DurationText.short(selected) : "Custom…",
          spokenTitle: isCustomSelected
            ? "Custom duration, \(DurationText.spoken(selected))" : "Custom duration",
          isSelected: isCustomSelected
        ) {
          showsCustom.toggle()
        }
      }
      if showsCustom { customRow }
    }
  }

  private var customRow: some View {
    HStack {
      Stepper(value: $customMinutes, in: Self.customRange, step: Self.customStep) {
        Text(DurationText.short(TimeInterval(customMinutes * 60))).monospacedDigit()
      }
      Spacer()
      Button("Start") {
        showsCustom = false
        model.startDuration(TimeInterval(customMinutes * 60))
      }
      .keyboardShortcut(.defaultAction)
    }
    .font(.subheadline)
  }
}

/// A small capsule button, highlighted when selected.
struct Chip: View {
  @Environment(\.accent) private var accent
  let title: String
  /// What VoiceOver reads, e.g. "1 hour" for "1 h".
  var spokenTitle: String?
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.caption.weight(isSelected ? .semibold : .regular))
        .lineLimit(1)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .foregroundStyle(isSelected ? Color.black : .primary)
        .background(isSelected ? accent : Color.primary.opacity(0.08), in: .capsule)
        .contentShape(.capsule)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(spokenTitle ?? title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(isSelected ? "Selected" : "")
  }
}
