import AppKit
import LisdexCore
import SwiftUI

/// Root of the left-click popover (spec: `.context/specs/lisdex-v1.md`).
/// Header (live status) · Keep Awake switch · mode picker with its per-mode controls · footer.
struct MenuView: View {
  let model: AppModel
  let dismiss: () -> Void
  let openSettings: (SettingsTab) -> Void

  /// Countdown text needs seconds; everything else changes at most once a minute.
  private var refreshInterval: TimeInterval {
    model.isOn && model.state.mode == .duration ? 1 : 15
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      TimelineView(.periodic(from: .now, by: refreshInterval)) { context in
        HeaderView(status: model.status(at: context.date))
      }
      Divider()
      ToggleRow(
        title: "Keep Awake",
        detail: "Prevent your Mac from sleeping.",
        isOn: Bindable(model).keepAwakeSwitch
      ) {
        TileGlyph(variant: model.settings.iconVariant, isOn: model.state.isOn)
      }
      if model.jigglerNeedsPermission {
        Button(action: PostEventPermission.openSettings) {
          Label {
            Text("Mouse jiggler needs permission")
          } icon: {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
          }
        }
        .buttonStyle(.link)
        .font(.caption)
      }
      Divider()
      Text("Mode").font(.subheadline).foregroundStyle(.secondary)
      ModePicker(selection: model.state.mode, select: model.setMode)
      switch model.state.mode {
      case .indefinitely: EmptyView()
      case .duration: DurationPanel(model: model)
      case .schedule:
        ScheduleCard(
          schedule: model.settings.schedule, update: model.setSchedule,
          editHours: { openSettings(.schedule) })
      }
      Divider()
      ToggleRow(
        title: "Start on Login",
        detail: loginDetail,
        isOn: Bindable(model).startOnLoginSwitch
      ) {
        Image(systemName: "arrow.up.forward.app").foregroundStyle(.secondary)
      }
      if model.loginItem == .needsApproval {
        Button("Allow in System Settings…", action: LoginItem.openSystemSettings)
          .buttonStyle(.link)
          .font(.caption)
      }
      Divider()
      footer
    }
    .padding(14)
    .frame(width: Theme.popoverWidth)
    .accent(model.settings.accent)
  }

  private var loginDetail: String {
    model.loginItem == .needsApproval
      ? "Waiting for your approval." : "Launch Lisdex when you log in."
  }

  private var footer: some View {
    VStack(spacing: 2) {
      MenuActionRow(
        symbol: "gearshape", title: "Settings…", shortcut: "⌘ ,", action: { openSettings(.general) }
      )
      .keyboardShortcut(",", modifiers: .command)
      Divider().padding(.leading, 36)
      MenuActionRow(symbol: "info.circle", title: "About Lisdex") {
        dismiss()
        AboutPanel.show()
      }
      Divider().padding(.leading, 36)
      MenuActionRow(symbol: "power", title: "Quit Lisdex", shortcut: "⌘ Q") {
        NSApp.terminate(nil)
      }
      .keyboardShortcut("q", modifiers: .command)
    }
  }
}

private struct HeaderView: View {
  let status: SessionStatus

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Lisdex").font(.title3.bold())
        Text(status.detail).font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
      }
      Spacer()
      StatusPill(pill: status.pill)
    }
  }
}

private struct StatusPill: View {
  @Environment(\.accent) private var accent
  let pill: SessionStatus.Pill

  var body: some View {
    let color: Color =
      switch pill {
      case .active: accent
      case .waiting: accent.opacity(0.6)
      case .inactive: .secondary
      }
    HStack(spacing: 5) {
      Circle().fill(color).frame(width: 6, height: 6)
      Text(pill.rawValue)
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(color)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(color.opacity(0.15), in: .capsule)
  }
}

/// The menu bar glyph inside the Keep Awake tile: accent and filled when on, grey outline when off.
private struct TileGlyph: View {
  @Environment(\.accent) private var accent
  let variant: MenuBarIconVariant
  let isOn: Bool

  var body: some View {
    Image(nsImage: MenuBarImages.image(for: MenuBarIcon(variant: variant, isActive: isOn)))
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(width: IconTile<EmptyView>.size - 6)
      .foregroundStyle(isOn ? accent : .secondary)
      .accessibilityHidden(true)
  }
}
