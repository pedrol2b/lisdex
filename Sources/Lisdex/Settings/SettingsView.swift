import LisdexCore
import SwiftUI

/// Raw values double as `-LisdexScreenshot` targets (`scripts/screenshots.sh`).
enum SettingsTab: String {
  case general, appearance, power, automation, shortcuts
}

/// Which Settings tab is showing; owned by the window controller so it can switch tabs on an
/// already open window (popover "Edit Hours…").
@MainActor @Observable
final class SettingsNavigation {
  var tab: SettingsTab = .general
}

/// Settings → General · Appearance · Power · Automation · Shortcuts (spec "Settings window",
/// ADR 0026). Every tab follows the same rules: each group has a heading; labels are sentence
/// case; an explanation is a grey line under the row it explains, only where the effect isn't
/// obvious; a footer is only for a note about the whole group.
struct SettingsView: View {
  static let width: CGFloat = 500

  let model: AppModel
  let navigation: SettingsNavigation

  var body: some View {
    TabView(selection: Bindable(navigation).tab) {
      GeneralSettingsView(model: model)
        .tabItem { Label("General", systemImage: "gearshape") }
        .tag(SettingsTab.general)
      AppearanceSettingsView(model: model)
        .tabItem { Label("Appearance", systemImage: "paintpalette") }
        .tag(SettingsTab.appearance)
      PowerSettingsView(model: model)
        .tabItem { Label("Power", systemImage: "bolt") }
        .tag(SettingsTab.power)
      AutomationSettingsView(model: model)
        .tabItem { Label("Automation", systemImage: "calendar.badge.clock") }
        .tag(SettingsTab.automation)
      ShortcutSettingsView(model: model)
        .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        .tag(SettingsTab.shortcuts)
    }
    .frame(width: Self.width)
    .fixedSize(horizontal: false, vertical: true)
    .accent(model.settings.accent)
  }
}

/// A group-wide note under a section, left-aligned like the macOS settings footers.
struct SectionFooter: View {
  let text: String

  init(_ text: String) { self.text = text }

  var body: some View {
    Text(text)
      .font(.caption)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
