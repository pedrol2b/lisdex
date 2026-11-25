import LisdexCore
import SwiftUI

/// Top of the popover (ADR 0027): is the Mac awake, and until when — a small caption, a large
/// headline, the timer's progress, and one wide Turn On / Turn Off button. Tinted with the accent
/// while Keep Awake holds (lighter while a schedule waits for its next window).
struct StatusCard: View {
  @Environment(\.accent) private var accent
  let status: SessionStatus
  let isOn: Bool
  let iconVariant: MenuBarIconVariant
  let toggle: () -> Void

  private var tint: Double {
    switch status.pill {
    case .active: 0.26
    case .waiting: 0.12
    case .inactive: 0
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 2) {
          Text(status.caption).font(.subheadline).foregroundStyle(.secondary)
          Text(status.headline).font(.title2.bold())
        }
        .monospacedDigit()
        .accessibilityElement(children: .combine)
        Spacer(minLength: 8)
        Image(nsImage: MenuBarImages.image(for: MenuBarIcon(variant: iconVariant, isActive: isOn)))
          .renderingMode(.template)
          .foregroundStyle(isOn ? accent : .secondary)
          .accessibilityHidden(true)
      }
      if let progress = status.progress {
        ProgressView(value: progress)
          .progressViewStyle(.linear)
          .tint(accent)
          .accessibilityLabel("Time elapsed")
      }
      Button(action: toggle) {
        Text(isOn ? "Turn Off" : "Turn On")
          .font(.body.weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 7)
          .foregroundStyle(isOn ? Color.black : .primary)
          .background(isOn ? accent : Color.primary.opacity(0.12), in: .rect(cornerRadius: 9))
          .contentShape(.rect)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isOn ? "Turn Keep Awake off" : "Turn Keep Awake on")
    }
    .padding(12)
    .background(
      LinearGradient(
        colors: [accent.opacity(tint), accent.opacity(tint * 0.4)], startPoint: .topLeading,
        endPoint: .bottomTrailing),
      in: .rect(cornerRadius: 12)
    )
    .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: 12))
  }
}

/// A problem with a side feature, under the status card: what stopped working, why, and one
/// button that fixes it. Disappears once fixed. Tinted with the accent, like the rest of the
/// popover (owner, 2026-11-25); the ⚠ symbol marks it as a warning (ADR 0027).
struct WarningBanner: View {
  @Environment(\.accent) private var accent
  let title: String
  let detail: String
  let actionTitle: String
  let action: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(accent)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 1) {
        Text(title).font(.subheadline.weight(.semibold))
        Text(detail).font(.caption).foregroundStyle(.secondary)
      }
      .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 6)
      Button(actionTitle, action: action)
        .controlSize(.small)
        .frame(maxHeight: .infinity)
    }
    .padding(10)
    .background(accent.opacity(0.12), in: .rect(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.35), lineWidth: 1))
    .accessibilityElement(children: .contain)
  }
}
