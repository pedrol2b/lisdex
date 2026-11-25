import AppKit
import LisdexCore
import SwiftUI

/// Root of the left-click popover (spec `lisdex-v1.md`, ADR 0027): status card · warnings ·
/// mode list with the selected mode's controls · Settings / About / Quit.
struct MenuView: View {
  let model: AppModel
  let dismiss: () -> Void
  let openSettings: (SettingsTab) -> Void

  /// Countdown text needs seconds; everything else changes at most once a minute.
  private var refreshInterval: TimeInterval {
    model.isOn && model.status(at: .now).progress != nil ? 1 : 15
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      TimelineView(.periodic(from: .now, by: refreshInterval)) { context in
        StatusCard(
          status: model.status(at: context.date), isOn: model.isOn,
          toggle: { model.switchOn(!model.isOn) })
      }
      warnings
      Divider()
      ModeList(
        selection: model.state.mode, summary: summary, select: model.setMode, controls: controls)
      Divider()
      footer
    }
    .padding(14)
    .frame(width: Theme.popoverWidth)
    .accent(model.settings.accent)
  }

  @ViewBuilder private var warnings: some View {
    if model.jigglerNeedsPermission {
      WarningBanner(
        title: "Mouse jiggler is paused", detail: "Lisdex needs Accessibility permission.",
        actionTitle: "Allow…", action: model.requestJigglerPermission)
    }
    if model.loginItem == .needsApproval {
      WarningBanner(
        title: "Start on login is waiting", detail: "Approve Lisdex in Login Items.",
        actionTitle: "Open…", action: LoginItem.openSystemSettings)
    }
  }

  /// The right-hand text of each mode row: what that mode would do now.
  private func summary(_ mode: KeepAwakeMode) -> String {
    switch mode {
    case .indefinitely: "until you stop"
    case .duration: DurationText.short(model.settings.duration)
    case .schedule: model.settings.schedule.daysSummary(calendar: .current)
    }
  }

  @ViewBuilder private func controls(_ mode: KeepAwakeMode) -> some View {
    switch mode {
    case .indefinitely: EmptyView()
    case .duration: DurationPanel(model: model)
    case .schedule:
      ScheduleCard(
        schedule: model.settings.schedule, update: model.setSchedule,
        editHours: { openSettings(.automation) })
    }
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
